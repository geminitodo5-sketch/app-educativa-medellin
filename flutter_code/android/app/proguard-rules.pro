# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# media_kit — keep all JNI/native bridge classes
-keep class com.alexmercerind.** { *; }
-dontwarn com.alexmercerind.**

# Keep native method signatures (required for JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all .so library names (prevents stripping from APK)
-keepattributes *Annotation*
-keep class * implements java.io.Serializable { *; }

# MediaPipe (flutter_gemma)
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# TFLite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Play Core — referenced by flutter_gemma/media_kit deferred components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Play Core SplitInstall (deferred components)
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Suppress all other missing-class warnings from deferred-component stubs
-ignorewarnings
