import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// این تابع باید یک تابع سطح بالا (top-level) یا یک متد استاتیک باشد
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // این خط برای استفاده از سایر پکیج‌ها در ایزولیت پس‌زمینه ضروری است
  DartPluginRegistrant.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  Timer? timer;
  
  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // منطق اصلی تایمر
  // خواندن مقدار قبلی شمارنده از حافظه
  int seconds = prefs.getInt('seconds_counter') ?? 0;

  timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      seconds++;

      // ارسال داده به UI
      service.invoke(
        'update',
        {
          "seconds": seconds, // ارسال مقدار شمارنده
        },
      );

      // ذخیره مقدار جدید شمارنده در حافظه
      await prefs.setInt('seconds_counter', seconds);

      // به‌روزرسانی نوتیفیکیشن
      // این کد فقط برای اندروید است و در وب اجرا نمی‌شود
      if (!kIsWeb && service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "تایمر در حال اجرا است",
            content: "زمان سپری شده: $seconds ثانیه", // نمایش زمان سپری شده
          );
        }
      }
    } catch (e) {
      // می‌توانید خطا را در اینجا ثبت کنید تا از کرش کردن سرویس جلوگیری شود
      debugPrint('An error occurred in the background service: $e');
    }
  });
}

Future<void> initializeService() async {
  // سرویس پس‌زمینه در وب پشتیبانی نمی‌شود، پس از تابع خارج می‌شویم.
  if (kIsWeb) return;

  final service = FlutterBackgroundService();

  // با توجه به آپدیت پکیج، کانال نوتیفیکیشن به صورت خودکار ساخته می‌شود.
  // نام کانال از initialNotificationTitle گرفته می‌شود.
  const notificationChannelId = 'my_app_channel'; // باید یکتا باشد
  const notificationId = 888; // یک عدد ثابت برای نوتیفیکیشن

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'سرویس پس‌زمینه برنامه من',
      initialNotificationContent: 'در حال آماده‌سازی...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) async {
        return true;
      },
    ),
  );
}