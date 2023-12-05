import 'package:livekit_client/livekit_client.dart';

class RoomDetailed {
  static Room? room;
 static EventsListener<RoomEvent>? listener;
 static String? rekam_medis;
} 

class ClassStatus {
  static String? speed;
  static String? jitter;
  static bool sedangcall = false;
  static String? flag;
  static String country = '';
}