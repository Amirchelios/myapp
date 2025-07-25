import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';

class ContactProvider with ChangeNotifier {
  List<Contact> _contacts = [];
  final Uuid _uuid = const Uuid();

  List<Contact> get contacts => _contacts;

  ContactProvider() {
    loadContacts();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/contacts.json');
  }

  Future<void> loadContacts() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.isNotEmpty) {
          final List<dynamic> json = jsonDecode(contents);
          _contacts = json.map((e) => Contact.fromJson(e)).toList();
        }
      }
    } catch (e) {
      // Handle error, maybe log it
    }
    notifyListeners();
  }

  Future<void> saveContacts() async {
    try {
      final file = await _localFile;
      final List<Map<String, dynamic>> json = _contacts.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Handle error
    }
  }

  void addContact(String name) {
    final newContact = Contact(id: _uuid.v4(), name: name);
    _contacts.add(newContact);
    saveContacts();
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts.removeWhere((contact) => contact.id == id);
    saveContacts();
    notifyListeners();
  }

  void updateContact(Contact updatedContact) {
    final index = _contacts.indexWhere((contact) => contact.id == updatedContact.id);
    if (index != -1) {
      _contacts[index] = updatedContact;
      saveContacts();
      notifyListeners();
    }
  }
}
