# Keep flutter_callkit_incoming classes to avoid obfuscation of keys
-keep class com.hiennv.flutter_callkit_incoming.** { *; }

# Twilio Programmable Voice
-keep class com.twilio.** { *; }
-keep class tvo.webrtc.** { *; }
-dontwarn tvo.webrtc.**
-keep class com.twilio.voice.** { *; }
-keepattributes InnerClasses
