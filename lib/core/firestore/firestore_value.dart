import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class FirestoreValue {
  static DateTime? date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static double doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  static int intValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return fallback;
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}
