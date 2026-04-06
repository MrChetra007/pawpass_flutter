# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Riverpod
-keep class riverpod.** { *; }
-dontwarn riverpod.**

# Keep GoRouter
-keep class go_router.** { *; }
-dontwarn go_router.**

# Keep JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.fasterxml.jackson.** { *; }

# Keep Google Sign-In
-keep class com.google.** { *; }
-keep class io.flutter.plugins.** { *; }
