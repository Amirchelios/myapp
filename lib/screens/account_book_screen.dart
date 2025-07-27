import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/contact_provider.dart';
import '../models/contact.dart';
import './contact_details_screen.dart';
import '../widgets/clearable_search_field.dart';

class AccountBookScreen extends StatefulWidget {
  const AccountBookScreen({super.key});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  String? _selectedContactId;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectContact(BuildContext context, String contactId) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    if (isLargeScreen) {
      setState(() {
        _selectedContactId = contactId;
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ContactDetailsScreen(contactId: contactId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر حساب'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportContacts();
              } else if (value == 'import') {
                _importContacts();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Text('استخراج اطلاعات'),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: Text('ورود اطلاعات'),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Web/Tablet layout
            return _buildWideLayout(context);
          } else {
            // Mobile layout
            return _buildNarrowLayout(context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContactList(BuildContext context, List<Contact> contacts, bool isWide) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClearableSearchField(
            controller: _searchController,
            hintText: 'جستجو',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(contacts[i].name),
              selected: isWide && _selectedContactId == contacts[i].id,
              onTap: () => _selectContact(context, contacts[i].id),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, contacts[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final contacts = Provider.of<ContactProvider>(context).contacts.where((c) {
      return c.name.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return Row(
      children: [
        SizedBox(
          width: 250,
          child: _buildContactList(context, contacts, true),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedContactId == null
              ? const Center(child: Text('یک مخاطب را انتخاب کنید'))
              : Consumer<ContactProvider>(
                  builder: (context, contactProvider, child) {
                    final contact = contactProvider.findContactById(_selectedContactId!);
                    return contact == null
                        ? const Center(child: Text('مخاطب یافت نشد.'))
                        : ContactDetailsView(
                            contact: contact,
                            key: ValueKey(_selectedContactId),
                          );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    final contacts = Provider.of<ContactProvider>(context).contacts.where((c) {
      return c.name.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();
    return _buildContactList(context, contacts, false);
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن مخاطب جدید'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'نام مخاطب'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('لغو'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('ذخیره'),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Provider.of<ContactProvider>(context, listen: false).addContact(name);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: Text('آیا از حذف مخاطب "${contact.name}" مطمئن هستید؟'),
        actions: [
          TextButton(
            child: const Text('لغو'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
            onPressed: () {
              Provider.of<ContactProvider>(context, listen: false).removeContact(contact.id);
              if (_selectedContactId == contact.id) {
                setState(() {
                  _selectedContactId = null;
                });
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportContacts() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final jsonString = contactProvider.getContactsAsJson();

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/contacts_export.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(filePath)], text: 'اطلاعات کاربران');
  }

  Future<void> _importContacts() async {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        await contactProvider.importContactsFromJson(jsonString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('اطلاعات با موفقیت وارد شد!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ورود اطلاعات: ${e.toString()}')),
        );
      }
    }
  }
}
