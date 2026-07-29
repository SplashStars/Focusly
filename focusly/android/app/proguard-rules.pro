# âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
# Focusly â ProGuard / R8 rules
# Version: 1.1.0
# âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

# ââ CRITICAL FIX: Gson TypeToken (flutter_local_notifications crash) âââââââââ
# Without these rules, R8 strips the generic type signature from TypeToken
# subclasses, causing: java.lang.RuntimeException: Missing type parameter.
# This manifests as a PlatformException when saving or cancelling a task.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep public class * implements java.lang.reflect.Type

# ââ flutter_local_notifications âââââââââââââââââââââââââââââââââââââââââââââââ
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }

# ââ Flutter engine ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ââ SQLite / sqflite âââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
-keep class com.tekartik.** { *; }

# ââ General Android ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator CREATOR;
}
-keepclassmembers class **.R$* { public static <fields>; }
-dontwarn com.google.android.gms.**

# Google Play Feature Delivery (required by Flutter FlutterPlayStoreSplitApplication)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
