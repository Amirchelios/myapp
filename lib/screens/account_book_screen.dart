import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  final Box<Contact> contactsBox = Hive.box<Contact>('contacts');
  Contact? _selectedContact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Pane (Contact List)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: contactsBox.listenable(),
                  builder: (context, Box<Contact> box, _) {
                    if (box.values.isEmpty) {
                      return const Center(child: Text('No contacts yet.'));
                    }
                    return ListView.builder(
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        final contact = box.getAt(index);
                        return ListTile(
                          title: Text(contact!.name),
                          onTap: () {
                            setState(() {
                              _selectedContact = contact;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Add new contact
                  },
                  child: const Text('Add Contact'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Pane (Contact Details)
        Expanded(
          flex: 2,
          child: _selectedContact == null
              ? const Center(child: Text('Select a contact to see details.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedContact!.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      // Add more details here
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
