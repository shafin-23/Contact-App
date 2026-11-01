import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../database/database_helper.dart';

class ContactFormScreen extends StatefulWidget {
  final Contact? contact;

  const ContactFormScreen({
    super.key,
    this.contact,
  });

  @override
  State<ContactFormScreen> createState() =>
      _ContactFormScreenState();
}

class _ContactFormScreenState
    extends State<ContactFormScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  bool isFavorite = false;
  bool isSaving = false;

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();

    final contact = widget.contact;

    nameController = TextEditingController(
      text: contact?.name ?? '',
    );

    phoneController = TextEditingController(
      text: contact?.phone ?? '',
    );

    emailController = TextEditingController(
      text: contact?.email ?? '',
    );

    addressController = TextEditingController(
      text: contact?.address ?? '',
    );

    isFavorite = contact?.isFavorite ?? false;
  }

  // Save Contact
  Future<void> saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final contact = Contact(
        id: widget.contact?.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        isFavorite: isFavorite,
      );

      if (isEditing) {
        await DatabaseHelper.instance.updateContact(
          contact,
        );
      } else {
        await DatabaseHelper.instance.insertContact(
          contact,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Contact updated successfully!'
                : 'Contact added successfully!',
          ),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving contact: $e'),
        ),
      );

      setState(() {
        isSaving = false;
      });
    }
  }

  // Reusable Input Field
  Widget buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,

        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),
        ),

        validator: validator ??
                (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Contact' : 'Add New Contact',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        isEditing
                            ? Icons.edit
                            : Icons.person_add_alt_1,
                        size: 38,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isEditing
                          ? 'Update Contact Details'
                          : 'Create New Contact',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Enter the contact information below',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Name
              buildInputField(
                label: 'Full Name',
                icon: Icons.person_outline,
                controller: nameController,
              ),

              // Phone
              buildInputField(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }

                  if (!RegExp(r'^[0-9+\-\s()]{7,20}$')
                      .hasMatch(value.trim())) {
                    return 'Enter a valid phone number';
                  }

                  return null;
                },
              ),

              // Email
              buildInputField(
                label: 'Email Address',
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }

                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }

                  return null;
                },
              ),

              // Address
              buildInputField(
                label: 'Address',
                icon: Icons.location_on_outlined,
                controller: addressController,
                maxLines: 3,
              ),

              // Favorite Option
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                  ),
                ),

                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Favorite Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: const Text(
                    'Add this contact to favorites',
                  ),

                  secondary: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),

                  value: isFavorite,

                  onChanged: (value) {
                    setState(() {
                      isFavorite = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveContact,

                  icon: Icon(
                    isEditing ? Icons.save : Icons.person_add,
                  ),

                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : isEditing
                        ? 'Update Contact'
                        : 'Save Contact',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(context),

                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}