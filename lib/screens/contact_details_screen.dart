import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void dispose() {
    _paymentController.dispose();
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
      total += (prices[itemName] ?? 0) * count;
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
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditNameDialog(context, widget.contact),
              ),
            ],
          ),
          const Divider(height: 20),
          ..._buildItemRows(context, widget.contact, contactProvider),
          const Divider(height: 20),
          _buildSummaryRow('مجموع بدهی:', numberFormat.format(totalDebt), Colors.red),
          _buildSummaryRow('بستانکاری:', numberFormat.format(widget.contact.credit), Colors.green),
          const Divider(height: 20),
          _buildPaymentSection(context, widget.contact, contactProvider, priceProvider),
        ],
      ),
    );
  }

  List<Widget> _buildItemRows(BuildContext context, Contact contact, ContactProvider provider) {
    final items = ["PC", "PS4", "بازی", "کیک", "نوشابه", "هایپ"];
    return items.map((itemName) {
      final count = contact.items[itemName] ?? 0;
      final isTimeBased = itemName == "PC" || itemName == "PS4";
      final controller = TextEditingController(text: count.toString());
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text('$itemName:', style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isTimeBased)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onSubmitted: (value) {
                    final intValue = int.tryParse(value) ?? 0;
                    provider.setItemValue(contact.id, itemName, intValue);
                  },
                ),
              )
            else ...[
              SizedBox(
                width: 40,
                child: Text(count.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
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
}
