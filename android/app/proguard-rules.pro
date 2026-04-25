# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase
-keep class supabase.** { *; }

# Keep model classes
-keep class com.sozin.pawpass.data.models.** { *; }

# QR code
-keep class qr_flutter.** { *; }

# PDF
-keep class pdf.** { *; }

# Share Plus
-keep class share_plus.** { *; }

-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Flutter embedding
-keep class io.flutter.embedding.** { *; }

# In App Purchase
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.vending.**

# Ignore all warnings
-dontwarn **

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}