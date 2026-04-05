import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/news_model.dart';

class PreferencesService {
  static const String _keyRegion = 'selected_region';
  static const String _keyOnboarding = 'onboarding_complete';
  static const String _keyTheme = 'is_dark_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyUsername = 'username';
  static const String _keyBio = 'bio';
  static const String _keyPhone = 'phone';
  static const String _keyLocation = 'location';
  static const String _keyMyNews = 'my_published_news';

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setRegion(String regionCode) async {
    final p = await prefs;
    await p.setString(_keyRegion, regionCode);
  }

  Future<String> getRegion() async {
    final p = await prefs;
    return p.getString(_keyRegion) ?? 'us';
  }

  String getRegionName(String code) {
    switch (code) {
      case 'us': return 'United States';
      case 'gb': return 'United Kingdom';
      case 'pk': return 'Pakistan';
      case 'in': return 'India';
      case 'ca': return 'Canada';
      case 'au': return 'Australia';
      case 'ae': return 'UAE';
      case 'sa': return 'Saudi Arabia';
      case 'sg': return 'Singapore';
      case 'za': return 'South Africa';
      default: return 'United States';
    }
  }

  Future<void> setOnboardingComplete() async {
    final p = await prefs;
    await p.setBool(_keyOnboarding, true);
  }

  Future<bool> isOnboardingComplete() async {
    final p = await prefs;
    return p.getBool(_keyOnboarding) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final p = await prefs;
    await p.setBool(_keyTheme, isDark);
  }

  Future<bool?> getDarkMode() async {
    final p = await prefs;
    return p.getBool(_keyTheme);
  }

  Future<void> setUsername(String username) async {
    final p = await prefs;
    await p.setString(_keyUsername, username);
  }

  Future<String?> getUsername() async {
    final p = await prefs;
    return p.getString(_keyUsername);
  }

  Future<void> setBio(String bio) async {
    final p = await prefs;
    await p.setString(_keyBio, bio);
  }

  Future<String?> getBio() async {
    final p = await prefs;
    return p.getString(_keyBio);
  }

  Future<void> setPhone(String phone) async {
    final p = await prefs;
    await p.setString(_keyPhone, phone);
  }

  Future<String?> getPhone() async {
    final p = await prefs;
    return p.getString(_keyPhone);
  }

  Future<void> setLocation(String location) async {
    final p = await prefs;
    await p.setString(_keyLocation, location);
  }

  Future<String?> getLocation() async {
    final p = await prefs;
    return p.getString(_keyLocation);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_keyNotifications, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final p = await prefs;
    return p.getBool(_keyNotifications) ?? true;
  }

  Future<void> saveMyNews(NewsModel news) async {
    final p = await prefs;
    final List<String> currentList = p.getStringList(_keyMyNews) ?? [];
    final String newsJson = jsonEncode(news.toJson());
    currentList.insert(0, newsJson);
    await p.setStringList(_keyMyNews, currentList);
  }

  Future<List<NewsModel>> getMyNews() async {
    final p = await prefs;
    final List<String> jsonList = p.getStringList(_keyMyNews) ?? [];
    return jsonList.map((String jsonStr) {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return NewsModel.fromJson(map);
    }).toList();
  }

  Future<void> deleteMyNews(NewsModel newsToDelete) async {
    final p = await prefs;
    final List<String> currentList = p.getStringList(_keyMyNews) ?? [];
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

    await p.setStringList(_keyMyNews, updatedList);
  }

  Future<void> clearSession() async {
    final p = await prefs;
    await p.remove(_keyOnboarding);
    await p.remove(_keyUsername);
    await p.remove(_keyBio);
    await p.remove(_keyPhone);
    await p.remove(_keyLocation);
  }
}
