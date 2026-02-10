import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';



class CallkitTestApp extends StatelessWidget {
  const CallkitTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Callkit Test', home: const CallkitTestPage());
  }
}

class CallkitTestPage extends StatefulWidget {
  const CallkitTestPage({super.key});

  @override
  State<CallkitTestPage> createState() => _CallkitTestPageState();
}

class _CallkitTestPageState extends State<CallkitTestPage> {
  final Uuid _uuid = const Uuid();
  String? _currentUuid;

  @override
  void initState() {
    super.initState();
    _ensureCallkitPermissions();
  }

  Future<void> _ensureCallkitPermissions() async {
    await FlutterCallkitIncoming.canUseFullScreenIntent();
    await FlutterCallkitIncoming.requestFullIntentPermission();
    await FlutterCallkitIncoming.requestNotificationPermission({
      "title": "Notification permission",
      "rationaleMessagePermission":
          "Notification permission is required, to show notification.",
      "postNotificationMessageRequired":
          "Notification permission is required, Please allow notification permission from setting.",
    });
  }

  Future<void> _showIncomingCall() async {
    await _ensureCallkitPermissions();
    _currentUuid = _uuid.v4();
    final CallKitParams callKitParams = CallKitParams(
      id: _currentUuid,
      nameCaller: 'Hien Nguyen',
      appName: 'Callkit',
      avatar: 'https://i.pravatar.cc/100',
      handle: '0123456789',
      type: 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Calling...',
        callbackText: 'Hang Up',
      ),
      duration: 30000,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        logoUrl: 'https://i.pravatar.cc/100',
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
        isShowCallID: false,
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }

  Future<void> _showMissedCallNotification() async {
    await _ensureCallkitPermissions();
    _currentUuid = _uuid.v4();
    final CallKitParams params = CallKitParams(
      id: _currentUuid,
      nameCaller: 'Hien Nguyen',
      handle: '0123456789',
      type: 1,
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowCallID: true,
      ),
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
    );
    await FlutterCallkitIncoming.showMissCallNotification(params);
  }

  Future<void> _startOutgoingCall() async {
    await _ensureCallkitPermissions();
    _currentUuid = _uuid.v4();
    final CallKitParams params = CallKitParams(
      id: _currentUuid,
      nameCaller: 'Hien Nguyen',
      handle: '0123456789',
      type: 1,
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      ios: IOSParams(handleType: 'generic'),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Calling...',
        callbackText: 'Hang Up',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowCallID: true,
      ),
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Callkit Test')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _showIncomingCall,
              child: const Text('Show Incoming Call'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showMissedCallNotification,
              child: const Text('Show Missed Call Notification'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startOutgoingCall,
              child: const Text('Start Outgoing Call'),
            ),
          ],
        ),
      ),
    );
  }
}
