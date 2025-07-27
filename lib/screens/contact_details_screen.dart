import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import '../providers/contact_provider.dart';
import '../providers/price_provider.dart';
import '../models/contact.dart';
import '../models/timer_models.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String contactId;

  const ContactDetailsScreen({required this.contactId, super.key});

  @override
  Widget build(BuildContext context) {
    final contact = Provider.of<ContactProvider>(context).findContactById(contactId);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact?.name ?? 'جزئیات مخاطب'),
      ),
      body: contact == null
          ? const Center(child: Text('مخاطب یافت نشد.'))
          : ContactDetailsView(contact: contact),
    );
  }
}

class ContactDetailsView extends StatefulWidget {
  final Contact contact;

  const ContactDetailsView({required this.contact, super.key});

  @override
  State<ContactDetailsView> createState() => _ContactDetailsViewState();
}

class _ContactDetailsViewState extends State<ContactDetailsView> {
  final TextEditingController _paymentController = TextEditingController();
  late final Map<String, TextEditingController> _itemControllers;
  late final Map<String, FocusNode> _itemFocusNodes;
  final List<String> _itemNames = const ["PC", "PS4", "بازی", "کیک", "نوشابه", "هایپ"];

  @override
  void initState() {
    super.initState();
    _itemControllers = {
      for (var itemName in _itemNames)
        itemName: TextEditingController()
    };
    _itemFocusNodes = {
      for (var itemName in _itemNames)
        itemName: FocusNode()
    };

    for (var itemName in _itemNames) {
      final isTimeBased = itemName == "PC" || itemName == "PS4";
      if (isTimeBased) {
        _itemFocusNodes[itemName]!.addListener(() {
          if (_itemFocusNodes[itemName]!.hasFocus) {
            _showTimePlayedDialog(itemName);
          } else {
            _updateTimeBasedItem(itemName);
          }
        });
      }
    }

    _updateControllerValuesFromContact(widget.contact);
  }

  @override
  void didUpdateWidget(covariant ContactDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contact != oldWidget.contact) {
      // Only update controllers if the corresponding field doesn't have focus
      bool hasFocus = _itemFocusNodes.values.any((node) => node.hasFocus);
      if (!hasFocus) {
        _updateControllerValuesFromContact(widget.contact);
      }
    }
  }

  void _updateControllerValuesFromContact(Contact contact) {
    contact.items.forEach((itemName, count) {
      final controller = _itemControllers[itemName];
      if (controller != null) {
        final isTimeBased = itemName == "PC" || itemName == "PS4";
        String newText;
        if (isTimeBased) {
          final hours = count / 60.0;
          newText = hours == hours.truncate() ? hours.truncate().toString() : hours.toStringAsFixed(2);
        } else {
          newText = count.toString();
        }
        
        if (controller.text != newText) {
          controller.text = newText;
        }
      }
    });
  }
  
  void _updateTimeBasedItem(String itemName) {
    final controller = _itemControllers[itemName]!;
    final provider = Provider.of<ContactProvider>(context, listen: false);
    final hours = double.tryParse(controller.text) ?? 0.0;
    final minutes = (hours * 60).round();
    
    if (widget.contact.items[itemName] != minutes) {
      provider.setItemValue(widget.contact.id, itemName, minutes);
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Map<String, double> _getPricesMap(Price price) {
    return {
      'PC': price.pc,
      'PS4': price.ps4,
      'بازی': price.game,
      'کیک': price.cake,
      'نوشابه': price.soda,
      'هایپ': price.hype,
    };
  }

  double _calculateTotalDebt(Contact contact, Map<String, double> prices) {
    double total = 0;
    contact.items.forEach((itemName, count) {
      final price = prices[itemName] ?? 0;
      if (itemName == 'PC' || itemName == 'PS4') {
        total += (price / 60.0) * count;
      } else {
        total += price * count;
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = Provider.of<ContactProvider>(context);
    final priceProvider = Provider.of<PriceProvider>(context);
    
    final pricesMap = _getPricesMap(priceProvider.price);
    final totalDebt = _calculateTotalDebt(widget.contact, pricesMap);
    final numberFormat = NumberFormat("#,##0", "en_US");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'جزئیات حساب: ${widget.contact.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    onPressed: () => _showResetConfirmationDialog(context, widget.contact),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditNameDialog(context, widget.contact),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          ..._buildItemRows(context, widget.contact, contactProvider),
          const Divider(height: 20),
          _buildSummaryRow('مجموع بدهی:', numberFormat.format(totalDebt.round()), Colors.red),
          _buildSummaryRow('بستانکاری:', numberFormat.format(widget.contact.credit), Colors.green),
          const Divider(height: 20),
          _buildPaymentSection(context, widget.contact, contactProvider, priceProvider),
        ],
      ),
    );
  }

  List<Widget> _buildItemRows(BuildContext context, Contact contact, ContactProvider provider) {
    return _itemNames.map((itemName) {
      final isTimeBased = itemName == "PC" || itemName == "PS4";
      final controller = _itemControllers[itemName]!;
      final focusNode = _itemFocusNodes[itemName]!;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text('$itemName:', style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isTimeBased)
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixText: 'ساعت',
                  ),
                  onSubmitted: (value) {
                    _updateTimeBasedItem(itemName);
                    FocusScope.of(context).unfocus();
                  },
                ),
              )
            else ...[
              SizedBox(
                width: 40,
                child: Text((contact.items[itemName] ?? 0).toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => provider.updateItemCount(contact.id, itemName, -1),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => provider.updateItemCount(contact.id, itemName, 1),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(
    BuildContext context,
    Contact contact,
    ContactProvider contactProvider,
    PriceProvider priceProvider,
  ) {
    return Row(
      children: [
        const Text('مبلغ پرداخت:'),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '0',
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          child: const Text('اعمال پرداخت'),
          onPressed: () {
            final paymentAmount = double.tryParse(_paymentController.text) ?? 0;
            if (paymentAmount > 0) {
              final pricesMap = _getPricesMap(priceProvider.price);
              contactProvider.applyPayment(contact.id, paymentAmount, pricesMap);
              _paymentController.clear();
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }

  void _showResetConfirmationDialog(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تایید ریست'),
          content: Text('آیا از ریست کردن حساب کاربری "${contact.name}" مطمئن هستید؟ تمام آیتم ها و بستانکاری صفر خواهند شد.'),
          actions: [
            TextButton(
              child: const Text('لغو'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ریست'),
              onPressed: () {
                Provider.of<ContactProvider>(context, listen: false).resetContactItems(contact.id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, Contact contact) {
    final TextEditingController nameController = TextEditingController(text: contact.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش نام'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'نام جدید'),
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
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Provider.of<ContactProvider>(context, listen: false).updateContactName(contact.id, newName);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTimePlayedDialog(String itemName) {
    final minutes = widget.contact.items[itemName] ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('مجموع زمان بازی شده برای $itemName'),
        content: Text('کل زمان بازی شده: $minutes دقیقه'),
        actions: [
          TextButton(
            child: const Text('باشه'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
