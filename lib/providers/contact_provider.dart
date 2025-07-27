import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';

class ContactProvider with ChangeNotifier {
  List<Contact> _contacts = [];
  final Uuid _uuid = const Uuid();

  List<Contact> get contacts => [..._contacts];

  ContactProvider() {
    loadContacts();
  }

  Contact? findContactById(String id) {
    try {
      return _contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
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
    final initialItems = {
      "PC": 0,
      "PS4": 0,
      "بازی": 0,
      "کیک": 0,
      "نوشابه": 0,
      "هایپ": 0,
    };
    final newContact = Contact(
      id: _uuid.v4(),
      name: name,
      items: initialItems,
      credit: 0,
    );
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

  void updateContactName(String id, String newName) {
    final contact = findContactById(id);
    if (contact != null) {
      final updatedContact = contact.copyWith(name: newName);
      updateContact(updatedContact);
    }
  }

  void updateItemCount(String contactId, String itemName, int change) {
    final contact = findContactById(contactId);
    if (contact != null) {
      final newItems = Map<String, int>.from(contact.items);
      final currentValue = newItems[itemName] ?? 0;
      final newValue = currentValue + change;

      if (newValue >= 0) {
        newItems[itemName] = newValue;
        final updatedContact = contact.copyWith(items: newItems);
        updateContact(updatedContact);
      }
    }
  }

  void setItemValue(String contactId, String itemName, int value) {
    final contact = findContactById(contactId);
    if (contact != null && value >= 0) {
      final newItems = Map<String, int>.from(contact.items);
      newItems[itemName] = value;
      final updatedContact = contact.copyWith(items: newItems);
      updateContact(updatedContact);
    }
  }

  void applyPayment(String contactId, double paymentAmount, Map<String, double> prices) {
    final contact = findContactById(contactId);
    if (contact == null) return;

    double totalAvailable = paymentAmount + contact.credit;
    final newItems = Map<String, int>.from(contact.items);

    final itemsPriority = ["PC", "PS4", "بازی", "کیک", "نوشابه", "هایپ"];

    for (var itemName in itemsPriority) {
      if (totalAvailable <= 0) break;

      final pricePerUnit = prices[itemName] ?? 0;
      if (pricePerUnit <= 0) continue;

      final currentUnits = newItems[itemName] ?? 0;
      if (currentUnits <= 0) continue;

      int unitsToPay = (totalAvailable / pricePerUnit).floor();
      unitsToPay = unitsToPay > currentUnits ? currentUnits : unitsToPay;

      if (unitsToPay > 0) {
        newItems[itemName] = currentUnits - unitsToPay;
        totalAvailable -= unitsToPay * pricePerUnit;
      }
    }

    final updatedContact = contact.copyWith(
      items: newItems,
      credit: totalAvailable > 0 ? totalAvailable : 0,
    );

    updateContact(updatedContact);
  }

  String getContactsAsJson() {
    final List<Map<String, dynamic>> jsonList = _contacts.map((e) => e.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonList);
  }

  Future<void> importContactsFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _contacts = jsonList.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
      await saveContacts();
      notifyListeners();
    } catch (e) {
      // Propagate error to be caught in the UI
      throw Exception('فایل نامعتبر است یا ساختار درستی ندارد.');
    }
  }
}
