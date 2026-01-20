// import 'dart:convert';
// import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

// class PusherService {
//   late PusherChannelsFlutter pusher;

//   Future<void> initPusher() async {
//     pusher = PusherChannelsFlutter.getInstance();

//     await pusher.init(
//       // ✅ POSITIONAL arguments (VERY IMPORTANT)
//       apiKey: "dsdsdsd1223adsdwe3ssas", // apiKey
//       cluster: "mt1", // cluster (dummy)
//       // ✅ NAMED optional callbacks
//       authEndpoint: "http://123.233.22.343:8000/broadcasting/auth",

//       onConnectionStateChange: (current, previous) {
//         print("🔌 STATE: $current");
//       },

//       onError: (message, code, error) {
//         print("❌ ERROR: $message ($code)");
//       },

//       onEvent: (event) {
//         print("📩 EVENT: ${event.eventName}");
//         print("📦 DATA: ${event.data}");

//         if (event.eventName == "message.sent") {
//           final data = jsonDecode(event.data);
//           print("💬 MESSAGE: ${data['message']}");
//         }
//       },
//     );

//     await pusher.subscribe(channelName: "private-chat.1");
//     await pusher.connect();
//   }

//   Future<void> disconnect() async {
//     await pusher.unsubscribe(channelName: "private-chat.1");
//     await pusher.disconnect();
//   }
// }
