import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../database/database_helper.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() =>
      _ContactListScreenState();
}

class _ContactListScreenState
    extends State<ContactListScreen> {

  List<Contact> contacts = [];

  bool isLoading = true;
  bool favoritesOnly = false;

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  // Load Contacts
  Future<void> loadContacts() async {
    final data = await DatabaseHelper.instance.getContacts(
      searchQuery: searchController.text.trim(),
      favoritesOnly: favoritesOnly,
    );

    if (!mounted) return;

    setState(() {
      contacts = data;
      isLoading = false;
    });
  }

  // Open Add/Edit Contact Screen
  Future<void> openContactForm([Contact? contact]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormScreen(contact: contact),
      ),
    );

    if (result == true) {
      loadContacts();
    }
  }

  // Delete Contact
  Future<void> deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteContact(
        contact.id!,
      );

      await loadContacts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact deleted successfully'),
        ),
      );
    }
  }

  // Toggle Favorite
  Future<void> toggleFavorite(Contact contact) async {
    final updatedContact = contact.copyWith(
      isFavorite: !contact.isFavorite,
    );

    await DatabaseHelper.instance.updateContact(
      updatedContact,
    );

    loadContacts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your contacts easily',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => loadContacts(),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    loadContacts();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Contacts'),
                  selected: !favoritesOnly,
                  onSelected: (value) {
                    setState(() {
                      favoritesOnly = false;
                      isLoading = true;
                    });
                    loadContacts();
                  },
                ),

                const SizedBox(width: 10),

                ChoiceChip(
                  avatar: const Icon(
                    Icons.favorite,
                    size: 16,
                  ),
                  label: const Text('Favorites'),
                  selected: favoritesOnly,
                  onSelected: (value) {
                    setState(() {
                      favoritesOnly = true;
                      isLoading = true;
                    });
                    loadContacts();
                  },
                ),
              ],
            ),
          ),

          // Contact Count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  favoritesOnly
                      ? 'Favorite Contacts'
                      : 'All Contacts',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${contacts.length} contacts',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Contact List
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : contacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    favoritesOnly
                        ? Icons.favorite_border
                        : Icons.contacts_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    searchController.text.isNotEmpty
                        ? 'No matching contacts found'
                        : favoritesOnly
                        ? 'No favorite contacts yet'
                        : 'No contacts available',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  16, 4, 16, 90),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.all(12),

                    onTap: () =>
                        openContactForm(contact),

                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name[0]
                            .toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),

                    title: Text(
                      contact.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Padding(
                      padding:
                      const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(contact.phone),
                          const SizedBox(height: 3),
                          Text(
                            contact.email,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          openContactForm(contact);
                        } else if (value == 'delete') {
                          deleteContact(contact);
                        } else if (value == 'favorite') {
                          toggleFavorite(contact);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),

                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                contact.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                contact.isFavorite
                                    ? 'Remove Favorite'
                                    : 'Add Favorite',
                              ),
                            ],
                          ),
                        ),

                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Add Contact Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openContactForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}