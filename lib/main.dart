import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:notifications/notifications.dart';
import 'package:wakelock/wakelock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Notifications? _notifications;
  bool started = false;
  String? notificationTitle;
  String? notificationMessage;
  bool musicPlaying = false;
  StreamSubscription<NotificationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    startListening();
  }

  void onData(NotificationEvent event) {
    setState(() {
      notificationTitle = event.title;
      notificationMessage = event.message;
    });

    if (notificationTitle == "Kunal Sms") {
      // Check if music is not already playing
      if (!musicPlaying) {
        // Play the custom ringtone
        FlutterRingtonePlayer.play(
          fromAsset: "lib/assets/music/ram_siya_ram_adipurush.mp3",
          looping: true,
          volume: 1,
          asAlarm: true,
        );
        setState(() {
          musicPlaying = true;
        });
      }
    }
  }

  void startListening() {
    _notifications = Notifications();
    _notifications!.notificationStream!.listen(onData);

    // Set up a background task to stop the music after 15 seconds (adjust as needed)
    Future.delayed(const Duration(seconds: 15), stopMusic);

    setState(() => started = true);
  }

  void stopListening() {
    _subscription?.cancel();
    stopMusic();
    setState(() {
      started = false;
      notificationTitle = null;
      notificationMessage = null;
    });
  }

  void stopMusic() {
    // Stop the music
    FlutterRingtonePlayer.stop();
    setState(() {
      musicPlaying = false;
    });
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
          tooltip: started ? 'Stop sensing' : 'Start sensing',
          child:
              started ? const Icon(Icons.stop) : const Icon(Icons.play_arrow),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Wakelock.disable();
    super.dispose();
  }
}
