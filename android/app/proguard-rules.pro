# Flutter Llama Android ProGuard Rules
-keep class com.write4me.llama_flutter_android.** { *; }
-keep interface com.write4me.llama_flutter_android.** { *; }

# Keep Kotlin function interfaces for JNI callbacks
-keep class kotlin.jvm.functions.** { *; }

# Also keep standard Flutter plugin classes
-keep class io.flutter.plugin.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep interface com.dexterous.flutterlocalnotifications.** { *; }

# Keep common serialization (Gson)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep models for serialization
-keep class com.example.beatspill.models.** { *; }
-keep class com.example.beatspill.services.NotificationService$** { *; }
