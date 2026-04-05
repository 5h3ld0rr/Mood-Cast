# Flutter ProGuard/R8 Rules

# Preserve Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve Google Services / Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep models sent to/from external APIs if they use reflection/GSON (though many use fromJson)
# Add your model packages here if needed:
# -keep class com.example.moodcast.models.** { *; }

# Just Audio / Audio Service
-keep class com.ryanheise.** { *; }

# Marquee
-keep class com.example.marquee.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Fix for R8 missing classes for Play Store Split / Deferred Components
-dontwarn com.google.android.play.core.**
