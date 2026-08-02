# ───────────────────────────────────────────────────────────────────────────
# Focusly – ProGuard / R8 rules
# Version: 1.1.0
# ───────────────────────────────────────────────────────────────────────────

# ── CRITICAL FIX: Gson TypeToken (flutter_local_notifications crash) ─────────
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep public class * implements java.lang.reflect.Type

# ── flutter_local_notifications ───────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# ── Flutter engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── SQLite / sqflite ─────────────────────────────────────────────────────────
-keep class com.tekartik.** { *; }

# ── Google Play Billing (in_app_purchase) ────────────────────────────────────
-keep class com.android.billingclient.** { *; }
-keep interface com.android.billingclient.** { *; }
-keepclassmembers class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# ── General Android ───────────────────────────────────────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}
-keepclassmembers class **.R$* { public static <fields>; }
-dontwarn com.google.android.gms.**

# Google Play Feature Delivery (required by Flutter FlutterPlayStoreSplitApplication)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
