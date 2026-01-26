import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/news_model.dart';

class PreferencesService {
  static const String _keyRegion = 'selected_region';
  static const String _keyOnboarding = 'onboarding_complete';
  static const String _keyTheme = 'is_dark_mode';

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Future<void> setRegion(String regionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegion, regionCode);
  }

  Future<String> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRegion) ?? 'us'; // Default to US
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarding) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isDark);
  }

  Future<bool?> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme);
  }

  static const String _keyUsername = 'username';
  static const String _keyBio = 'bio';
  static const String _keyPhone = 'phone';
  static const String _keyLocation = 'location';

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<void> setBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBio, bio);
  }

  Future<String?> getBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBio);
  }

  Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  Future<void> setLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocation, location);
  }

  Future<String?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocation);
  }

  static const String _keyNotifications = 'notifications_enabled';

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true; // Default to true
  }

  static const String _keyMyNews = 'my_published_news';

  Future<void> saveMyNews(NewsModel news) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentList = prefs.getStringList(_keyMyNews) ?? [];

    // Convert news object to JSON string
    final String newsJson = jsonEncode(news.toJson());

    // Add to beginning of list (newest first)
    currentList.insert(0, newsJson);

    await prefs.setStringList(_keyMyNews, currentList);
  }

  Future<List<NewsModel>> getMyNews() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = prefs.getStringList(_keyMyNews) ?? [];

    return jsonList.map((String jsonStr) {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return NewsModel.fromJson(map);
    }).toList();
  }

  Future<void> deleteMyNews(NewsModel newsToDelete) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentList = prefs.getStringList(_keyMyNews) ?? [];

    // Convert the news to delete to JSON for comparison, or filter
    // Here we will decode, filter, and re-encode to be safe
    List<NewsModel> models = currentList
        .map((str) => NewsModel.fromJson(jsonDecode(str)))
        .toList();

    models.removeWhere(
      (item) =>
          item.title == newsToDelete.title &&
          item.publishedAt == newsToDelete.publishedAt,
    );

    final List<String> updatedList = models
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_keyMyNews, updatedList);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboarding);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyBio);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyLocation);
    // keeping region, theme, notifications, and my_news for now
  }
}
