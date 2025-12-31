plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.chrono_application"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.chrono_application"
        // Ensure this line is present and set to 21 or higher for coroutines and modern libraries.
        minSdk = 21 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// === DEPENDENCIES BLOCK (FIXED KOTLIN DSL SYNTAX) ===
dependencies {
    // Add Coroutines support for asynchronous programming in Kotlin (REQUIRED for MainActivity.kt logic)
    // Corrected from Groovy (") to Kotlin DSL (())
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3") 
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Placeholder for ChronosNav SDK (You must replace this with the actual dependency)
    // implementation("com.chronosnav:android-sdk:1.0.0") 
    // implementation(files("libs/chronosnav-sdk.aar")) 
}