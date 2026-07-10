# ─────────────────────────────────────────────────────────────────────────────
# Focusly — ProGuard / R8 rules
# Version: 1.1.0
# ─────────────────────────────────────────────────────────────────────────────

# ── CRITICAL FIX: Gson TypeToken (flutter_local_notifications crash) ─────────
# Without these rules, R8 strips the generic type signature from TypeToken
# subclasses, causing: java.lang.RuntimeException: Missing type parameter.
# This manifests as a PlatformException when saving or cancelling a task.
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

# ── General Android ──────────────────────────────────────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}
-keepclassmembers class **.R$* { public static <fields>; }
-dontwarn com.google.android.gms.**
