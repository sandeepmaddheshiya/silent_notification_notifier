import 'dart:async';
import 'dart:developer';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:notifications/notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';

void backgroundTask() {
  // Acquire a wakelock to keep the device awake during the background task
  Wakelock.enable();

  // Code to be executed in the background
  // You can put your background task logic here

  // Release the wakelock when the task is complete
  Wakelock.disable();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions
  await _requestPermissions();

  // Initialize the wakelock plugin
  Wakelock.enable();

  // Initialize the background task
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

Future<void> _requestPermissions() async {
  await Permission.notification.request();
  await Permission.ignoreBatteryOptimizations.request();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Notifications? _notifications;
  StreamSubscription<NotificationEvent>? _subscription;
  bool started = false;
  String? notificationTitle;
  String? notificationMessage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  void onData(NotificationEvent event) {
    setState(() {
      notificationTitle = event.title;
      notificationMessage = event.message;
    });

    log("Title: $notificationTitle");
    log("Message: $notificationMessage");

    // Check if the notification title matches the specified title
    if (notificationTitle == "Kunal Sms") {
      // Play the custom ringtone
      FlutterRingtonePlayer.play(
        fromAsset: "lib/assets/music/ram_siya_ram_adipurush.mp3",
        looping: true,
        volume: 1,
        asAlarm: true,
      );
    }

    log(event.toString());
  }

  void startListening() {
    _notifications = Notifications();
    try {
      _subscription = _notifications!.notificationStream!.listen(onData);
      setState(() => started = true);
    } on NotificationException catch (exception) {
      log(exception.toString());
    }

    // Schedule the background task to run periodically
    AndroidAlarmManager.periodic(
        const Duration(minutes: 15), 0, backgroundTask);
  }

  void stopListening() {
    _subscription?.cancel();
    setState(() {
      started = false;
      notificationTitle = null;
      notificationMessage = null;
    });

    // Cancel the background task when not needed
    AndroidAlarmManager.cancel(0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications Example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Listening to notifications..."),
              const SizedBox(height: 20),
              Text("Title: $notificationTitle"),
              Text("Message: $notificationMessage"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: started ? stopListening : startListening,
          tooltip: 'Start/Stop sensing',
          child:
              started ? const Icon(Icons.stop) : const Icon(Icons.play_arrow),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Release the wakelock when the app is disposed
    Wakelock.disable();
    super.dispose();
  }
}
