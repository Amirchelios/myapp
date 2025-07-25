import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  Contact? _selectedContact;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, child) {
        final filteredContacts = contactProvider.contacts
            .where((c) => c.name.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();

        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return ListTile(
                          title: Text(contact.name),
                          onTap: () => setState(() => _selectedContact = contact),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => contactProvider.removeContact(contact.id),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => _showAddContactDialog(context, contactProvider),
                      child: const Text('Add Contact'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _selectedContact == null
                  ? const Center(child: Text('Select a contact to see details.'))
                  : _buildContactDetails(context, contactProvider, _selectedContact!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactDetails(BuildContext context, ContactProvider provider, Contact contact) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                contact.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditContactDialog(context, provider, contact),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Implement debt details
          Text('Debts: ${contact.debt}'),
          const SizedBox(height: 16),
          Text('Credit: ${contact.credit}'),
          const SizedBox(height: 16),
          // Implement payment
          TextField(
            controller: _paymentController,
            decoration: const InputDecoration(
              labelText: 'Payment Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implement payment logic
            },
            child: const Text('Apply Payment'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, ContactProvider provider) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Contact'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                provider.addContact(nameController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(BuildContext context, ContactProvider provider, Contact contact) {
    final nameController = TextEditingController(text: contact.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedContact = Contact(
                  id: contact.id,
                  name: nameController.text,
                  debt: contact.debt,
                  credit: contact.credit,
                );
                provider.updateContact(updatedContact);
                setState(() => _selectedContact = updatedContact);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
