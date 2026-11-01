# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep public class * extends io.flutter.plugin.common.PluginRegistry
-keep public class * extends io.flutter.embedding.engine.plugins.FlutterPlugin

# Keep Pigeon generated APIs
-keep class dev.flutter.pigeon.** { *; }
-keep class * implements io.flutter.plugin.common.BasicMessageChannel$MessageHandler { *; }

# Keep Kotlin reflection / Coroutines
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-dontwarn io.flutter.plugins.**

