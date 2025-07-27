import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/price_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/group_timer_card.dart';
import '../models/timer_models.dart';
import '../providers/contact_provider.dart';
import '../widgets/clearable_search_field.dart';

class GameTableScreen extends StatelessWidget {
  const GameTableScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return _buildWideLayout();
        } else {
          return _buildNarrowLayout();
        }
      },
    );
  }

  Widget _buildDeviceGrid(TimerProvider timerProvider, {required SliverGridDelegate gridDelegate}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: gridDelegate,
      itemCount: timerProvider.devices.length,
      itemBuilder: (context, index) {
        final device = timerProvider.devices[index];
        return DeviceCard(
          device: device,
          onTap: () => _onDeviceTapped(context, device),
        );
      },
    );
  }

  Widget _buildGroupList(TimerProvider timerProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: timerProvider.groups.length,
      itemBuilder: (context, index) {
        final group = timerProvider.groups[index];
        return GroupTimerCard(
          group: group,
          onTap: () => _onGroupTapped(context, group),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        return Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              flex: 3,
              child: _buildDeviceGrid(timerProvider,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150.0,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.0,
                  )),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 1,
              child: _buildGroupList(timerProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowLayout() {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        return Column(
          children: [
            Expanded(
              flex: 3,
              child: _buildDeviceGrid(timerProvider,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.0,
                  )),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 1,
              child: _buildGroupList(timerProvider),
            ),
          ],
        );
      },
    );
  }

  void _onDeviceTapped(BuildContext context, DeviceTimer device) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final priceProvider = Provider.of<PriceProvider>(context, listen: false);

    if (device.isActive) {
      // If timer is active, show confirmation dialog
      final Duration elapsedTime = Duration(seconds: device.seconds);
      final double pricePerMinute = device.type == 'PC'
          ? priceProvider.price.pc / 60.0
          : priceProvider.price.ps4 / 60.0;
      final double totalCost = (device.seconds * pricePerMinute);

      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('پایان نشست؟'),
            content: Text(
                'زمان سپری شده: ${_formatDuration(elapsedTime)}\nمبلغ قابل پرداخت: ${totalCost.toStringAsFixed(0)} تومان'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // لغو
                child: const Text('ادامه تایمر'),
              ),
              TextButton(
                onPressed: () {
                  timerProvider.stopDeviceTimer(device.id);
                  Navigator.of(context).pop();
                  // TODO: Implement Payment Logic
                },
                child: const Text('پرداخت'),
              ),
              TextButton(
                onPressed: () {
                  timerProvider.stopDeviceTimer(device.id);
                   Navigator.of(context).pop();
                   _showContactSelectionForDebt(context, device.type == 'PC' ? 'PC' : 'PS4', totalCost);
                },
                child: const Text('افزودن به حساب دفتری'),
              ),
            ],
          ),
        ),
      );
    } else {
      // If timer is not active, start it
      timerProvider.toggleDeviceTimer(device.id);
    }
  }

  void _showContactSelectionForDebt(
      BuildContext context, String itemType, double amount) {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredContacts = contactProvider.contacts.where((contact) {
              return contact.name
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase());
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('انتخاب کاربر برای ثبت بدهی'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClearableSearchField(
                        controller: searchController,
                        hintText: 'جستجو...',
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            return ListTile(
                              title: Text(contact.name, textAlign: TextAlign.right),
                              onTap: () {
                                final updatedItems = Map<String, int>.from(contact.items);
                                // Store cost as integer, assuming price is in integer units (e.g., Tomans)
                                updatedItems[itemType] = (updatedItems[itemType] ?? 0) + amount.round();
                                contactProvider.updateContact(contact.copyWith(items: updatedItems));
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('لغو'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onGroupTapped(BuildContext context, GroupTimer group) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (group.isActive) {
      timerProvider.toggleGroupTimer(group.id); // Stop the group timer
      _showLoserSelection(context, group.id); // Show loser selection dialog
    } else {
      timerProvider.toggleGroupTimer(group.id);
    }
  }

   void _showLoserSelection(BuildContext context, String groupId) {
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    List<String> selectedLoserIds = [];
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final allContacts = contactProvider.contacts;
            final filteredContacts = allContacts.where((contact) {
              final searchTerm = searchController.text.toLowerCase();
              return contact.name.toLowerCase().contains(searchTerm);
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('انتخاب بازندگان'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClearableSearchField(
                        controller: searchController,
                        hintText: 'جستجو...',
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            final isSelected = selectedLoserIds.contains(contact.id);
                            return CheckboxListTile(
                              title: Text(contact.name, textAlign: TextAlign.right),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedLoserIds.add(contact.id);
                                  } else {
                                    selectedLoserIds.remove(contact.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('لغو'),
                  ),
                  TextButton(
                    onPressed: () {
                      for (String contactId in selectedLoserIds) {
                        final contact = contactProvider.contacts.firstWhere((c) => c.id == contactId);
                        final updatedItems = Map<String, int>.from(contact.items);
                        updatedItems['بازی'] = (updatedItems['بازی'] ?? 0) + 1;
                        contactProvider.updateContact(contact.copyWith(items: updatedItems));
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('تایید'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
