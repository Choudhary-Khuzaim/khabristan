# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep http package classes
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Keep webview classes
-keep class android.webkit.** { *; }

# Keep Gson / JSON serialization classes if any
-keepattributes *Annotation*
-keepattributes Signature

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
