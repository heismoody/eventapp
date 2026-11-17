import java.io.FileInputStream
import java.util.Properties

// Release signing key, never committed: android/key.properties points at
// the keystore. Locally it lives in ~/.cardly/; CI writes both from GitHub
// secrets. Every release of a given app must be signed with this same key,
// or Android refuses the update.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "tz.co.cardly.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "tz.co.cardly.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // dev and prod install side by side: different package id and launcher
    // name, and the Dart side (AppEnvironment) reads the flavor to pick the
    // server. Build with `--flavor dev` or `--flavor prod`.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Cardly Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Cardly")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Signed like the real app when the key is on this machine, so
            // `flutter run --flavor dev` installs over the Cardly Dev app from
            // appdev (keeping its data) instead of failing on a key mismatch
            // or adding a second, differently-signed app. CI never builds debug.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            // Without key.properties (e.g. a fresh clone) fall back to the
            // debug key so `flutter run --release` still works — but such an
            // APK can never update a real install, so it must not be published.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Google Play in-app updates (the Play build asks Play for a newer
    // version itself, see PlayUpdates.kt). Google's own library.
    implementation("com.google.android.play:app-update:2.1.0")
}
