plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google Services plugin to read your google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "com.app.attendinn.attendinn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Updated to compilerOptions DSL to resolve deprecation warning
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // Must match your Firebase Console Package Name
        applicationId = "com.app.attendinn.attendinn"

        // Recommended for Firebase projects
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required for large libraries like Firebase
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM (Bill of Materials) - Updated to latest version
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    // Add Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}
