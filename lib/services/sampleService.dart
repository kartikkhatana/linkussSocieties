import 'package:shared_preferences/shared_preferences.dart';

updateUserLocally(String name, String email, 
    String college) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("name", name);
  prefs.setString("email", email);
  prefs.setString("college", college);
}
