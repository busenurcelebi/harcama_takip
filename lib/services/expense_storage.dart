import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseStorage {
  static const String _key = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data =
        expenses.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(data);
    await prefs.setString(_key, jsonString);
  }
}
