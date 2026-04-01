import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CheckInService {
  static const String key = "checkin_history";

  static Future<void> addCheckIn(
  String fairName,
  String location,
  int points,
) async {
  final prefs = await SharedPreferences.getInstance();

  List<String> history = prefs.getStringList(key) ?? [];

  String formattedTime =
      DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  final newEntry = jsonEncode({
    "fairName": fairName,
    "location": location,
    "points": points,
    "time": formattedTime,
  });

  history.add(newEntry);

  await prefs.setStringList(key, history);
}

  /// Retrieve check-in history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(key) ?? [];

    return history
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}