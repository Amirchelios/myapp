import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/price_provider.dart';
import '../models/timer_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Price _price;

  @override
  Widget build(BuildContext context) {
    return Consumer<PriceProvider>(
      builder: (context, priceProvider, child) {
        _price = priceProvider.price;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
              children: [
                TextFormField(
                  initialValue: _price.pc.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت هر دقیقه کامپیوتر'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.pc = double.tryParse(value ?? '0') ?? 0,
                ),
                TextFormField(
                  initialValue: _price.ps4.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت هر دقیقه پلی‌استیشن ۴'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.ps4 = double.tryParse(value ?? '0') ?? 0,
                ),
                TextFormField(
                  initialValue: _price.cake.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت کیک'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.cake = double.tryParse(value ?? '0') ?? 0,
                ),
                TextFormField(
                  initialValue: _price.soda.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت نوشابه'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.soda = double.tryParse(value ?? '0') ?? 0,
                ),
                TextFormField(
                  initialValue: _price.hype.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت هایپ'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.hype = double.tryParse(value ?? '0') ?? 0,
                ),
                TextFormField(
                  initialValue: _price.game.toString(),
                  textAlign: TextAlign.right, // Align text to the right
                  decoration: const InputDecoration(labelText: 'قیمت هر دست بازی'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _price.game = double.tryParse(value ?? '0') ?? 0,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      priceProvider.setPrice(_price);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('قیمت‌ها ذخیره شدند!')),
                      );
                    }
                  },
                  child: const Text('ذخیره قیمت‌ها'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
