import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _emailKey = 'auth_email';
  static const String _passwordKey = 'auth_password';

  Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    return email != null && password != null;
  }

  Future<void> registerUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
  }

  Future<bool> validateLogin(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final savedPassword = prefs.getString(_passwordKey);

    if (savedEmail == null || savedPassword == null) {
      return false; // hiç kullanıcı yok
    }

    return savedEmail == email && savedPassword == password;
  }
}
