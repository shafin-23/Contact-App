
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

  bool isLoading = true;
  bool favoritesOnly = false;

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // Load Contacts and Statistics
  Future<void> loadContacts({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final results = await Future.wait<List<Contact>>([
        DatabaseHelper.instance.getContacts(
          searchQuery: searchController.text.trim(),
          favoritesOnly: favoritesOnly,
        ),
        DatabaseHelper.instance.getContacts(),
      ]);

      final filteredContacts = results[0];
      final allContacts = results[1];

      if (!mounted) return;

      setState(() {
        contacts = filteredContacts;
        totalContacts = allContacts.length;
        favoriteCount = allContacts
            .where((contact) => contact.isFavorite)
            .length;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load contacts: $e'),
        ),
      );
    }
  }

  // Open Add/Edit Contact Screen
  Future<void> openContactForm([Contact? contact]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormScreen(contact: contact),
      ),
    );

    if (result == true && mounted) {
      await loadContacts();
    }
  }

  // Delete Contact
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

    if (confirm != true) return;

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
        SnackBar(
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }

  // Toggle Favorite
  Future<void> toggleFavorite(Contact contact) async {
    try {
      final updatedContact = contact.copyWith(
        isFavorite: !contact.isFavorite,
      );

      await DatabaseHelper.instance.updateContact(
        updatedContact,
      );

      await loadContacts(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
        ),
      );
    }
  }

  // Generate Avatar Color
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
      backgroundColor: Colors.grey.shade50,

      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: loadContacts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 115),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),

                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                ),

                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      _buildFilter(
                        'All Contacts',
                        !favoritesOnly,
                            () {
                          setState(() {
                            favoritesOnly = false;
                          });
                          loadContacts();
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFilter(
                        'Favorites',
                        favoritesOnly,
                            () {
                          setState(() {
                            favoritesOnly = true;
                          });
                          loadContacts();
                        },
                      ),
                    ],
                  ),
                ),

                // List Heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        favoritesOnly
                            ? 'Favorite Contacts'
                            : 'All Contacts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${contacts.length} found',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading / Empty / Contact List
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 70),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (contacts.isEmpty)
                  _buildEmptyState()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Column(
                      children: contacts
                          .map(
                            (contact) =>
                            _buildContactCard(contact),
                      )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      // Fixed Bottom Glass Dock
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildGlassDock(),
    );
  }

  // Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
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
                  'Your connections, all in one place.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  // Statistics Card
  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color iconColor,
      Color backgroundColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter Button
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
          horizontal: 18,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            if (title == 'Favorites') ...[
              Icon(
                Icons.favorite_rounded,
                size: 15,
                color: selected
                    ? Colors.white
                    : AppColors.favorite,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : AppColors.textGrey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Contact Card
  Widget _buildContactCard(Contact contact) {
    final hasEmail = contact.email.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: avatarColor(contact.name),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty
                    ? contact.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          // Contact Details
          Expanded(
            child: InkWell(
              onTap: () => openContactForm(contact),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            contact.phone,
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

                    if (hasEmail) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 13,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              contact.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
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

          // Favorite and More Options
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => toggleFavorite(contact),
                icon: Icon(
                  contact.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: contact.isFavorite
                      ? AppColors.favorite
                      : AppColors.textGrey,
                ),
              ),

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
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
                        Icon(
                          Icons.edit_outlined,
                          size: 19,
                        ),
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

  // Empty State
  Widget _buildEmptyState() {
    final isSearching =
        searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
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
              size: 45,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

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
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => openContactForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add your first contact'),
            ),
          ],
        ],
      ),
    );
  }

  // Fixed Glass Dock: Search + Add Button
  Widget _buildGlassDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(225),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(220),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFBBDEFB),
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: false,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        loadContacts(showLoader: false);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 21,
                        ),
                        suffixIcon:
                        searchController.text.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                            loadContacts(
                              showLoader: false,
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                          ),
                        )
                            : null,
                        contentPadding:
                        const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Compact Add Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => openContactForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
