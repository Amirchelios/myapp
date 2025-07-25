import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/contact.dart';

class ContactProvider extends ChangeNotifier {
  late Box<Contact> _contactBox;

  List<Contact> _contacts = [];
  List<Contact> get contacts => _contacts;

  ContactProvider() {
    _init();
  }

  Future<void> _init() async {
    _contactBox = await Hive.openBox<Contact>('contacts');
    _contacts = _contactBox.values.toList();
    notifyListeners();
  }

  Future<void> addContact(Contact contact) async {
    await _contactBox.add(contact);
    _contacts = _contactBox.values.toList();
    notifyListeners();
  }

  Future<void> updateContact(int index, Contact contact) async {
    await _contactBox.putAt(index, contact);
    _contacts = _contactBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteContact(int index) async {
    await _contactBox.deleteAt(index);
    _contacts = _contactBox.values.toList();
    notifyListeners();
  }
}
