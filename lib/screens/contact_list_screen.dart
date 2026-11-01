
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../database/database_helper.dart';
import '../app_colors.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> contacts = [];

  int totalContacts = 0;
  int favoriteCount = 0;
  int _loadRequestId = 0;

  bool isLoading = true;
  bool favoritesOnly = false;

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // Load contacts and statistics
  Future<void> loadContacts({bool showLoader = true}) async {
    final requestId = ++_loadRequestId;

    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final filteredContacts =
      await DatabaseHelper.instance.getContacts(
        searchQuery: searchController.text.trim(),
        favoritesOnly: favoritesOnly,
      );

      final allContacts =
      await DatabaseHelper.instance.getContacts();

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        contacts = filteredContacts;
        totalContacts = allContacts.length;
        favoriteCount =
            allContacts.where((c) => c.isFavorite).length;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load contacts: $e')),
      );
    }
  }

  // Open Add/Edit screen
  Future<void> openContactForm([Contact? contact]) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormScreen(contact: contact),
      ),
    );

    if (result == true && mounted) {
      loadContacts();
    }
  }

  // Delete contact
  Future<void> deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.favorite,
          size: 35,
        ),
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.favorite,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteContact(contact.id!);

        if (!mounted) return;

        await loadContacts();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(Contact contact) async {
    try {
      final updatedContact = contact.copyWith(
        isFavorite: !contact.isFavorite,
      );

      await DatabaseHelper.instance.updateContact(updatedContact);

      await loadContacts(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  // Generate avatar color
  Color avatarColor(String name) {
    final colors = [
      const Color(0xFFEAE5FF),
      const Color(0xFFFFE8E8),
      const Color(0xFFE2F4ED),
      const Color(0xFFFFF0D9),
      const Color(0xFFE1EEFF),
      const Color(0xFFFCE4F3),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: loadContacts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              SliverToBoxAdapter(
                child: _buildStatistics(),
              ),

              SliverToBoxAdapter(
                child: _buildFilters(),
              ),

              SliverToBoxAdapter(
                child: _buildListHeading(),
              ),

              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (contacts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    2,
                    20,
                    24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _buildContactCard(contacts[index]);
                      },
                      childCount: contacts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Fixed bottom search and add dock
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildGlassDock(),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTACTLY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'My Contacts',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage connections effortlessly.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  // Statistics cards
  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Contacts',
              totalContacts.toString(),
              Icons.people_outline_rounded,
              const Color(0xFF6956D9),
              const Color(0xFFEDE9FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Favorites',
              favoriteCount.toString(),
              Icons.favorite_rounded,
              const Color(0xFFE85D75),
              const Color(0xFFFFE8EC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color iconColor,
      Color backgroundColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter tabs
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilter(
            'All Contacts',
            !favoritesOnly,
                () {
              setState(() => favoritesOnly = false);
              loadContacts();
            },
          ),
          const SizedBox(width: 10),
          _buildFilter(
            'Favorites',
            favoritesOnly,
                () {
              setState(() => favoritesOnly = true);
              loadContacts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(
      String title,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title == 'Favorites') ...[
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: selected
                    ? Colors.white
                    : AppColors.favorite,
              ),
              const SizedBox(width: 7),
            ],
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.textGrey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Contact list heading
  Widget _buildListHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            favoritesOnly ? 'Favorite Contacts' : 'All Contacts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: AppColors.textDark,
            ),
          ),
          Text(
            '${contacts.length} found',
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Contact card
  Widget _buildContactCard(Contact contact) {
    final hasEmail = contact.email.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: avatarColor(contact.name),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => openContactForm(contact),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contact.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasEmail) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              contact.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                onPressed: () => toggleFavorite(contact),
                icon: Icon(
                  contact.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: contact.isFavorite
                      ? AppColors.favorite
                      : AppColors.textGrey,
                  size: 23,
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: 38,
                ),
                iconSize: 22,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textGrey,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    openContactForm(contact);
                  } else if (value == 'delete') {
                    deleteContact(contact);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: AppColors.favorite,
                        ),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom search and add dock
  Widget _buildGlassDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7FF),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,

                      // Unfocus search when tapping outside
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },

                      onChanged: (_) {
                        setState(() {});
                        loadContacts(showLoader: false);
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 23,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                            loadContacts(showLoader: false);
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: AppColors.textGrey,
                          ),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => openContactForm(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 22,
                    ),
                    label: const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    final isSearching = searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 95,
              width: 95,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : favoritesOnly
                    ? Icons.favorite_border_rounded
                    : Icons.people_outline_rounded,
                size: 43,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching
                  ? 'No contacts found'
                  : favoritesOnly
                  ? 'No favorite contacts'
                  : 'No contacts yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try searching with another name.'
                  : favoritesOnly
                  ? 'Mark a contact as favorite to see it here.'
                  : 'Start building your contact list today.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
            if (!isSearching && !favoritesOnly) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => openContactForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add your first contact'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
