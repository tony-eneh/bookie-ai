import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads key.properties (git-ignored). The keystore itself lives
// outside the repo; never regenerate it or installed APKs can't be updated.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.bookieai.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bookieai.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }

        release {
            // Debug keys only for local runs; see the release guard below.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Refuse to produce a debug-signed release APK/AAB by accident: such a build
// can't be installed over the real app and can never be updated. Set
// ALLOW_DEBUG_SIGNED_RELEASE=1 for a throwaway local release build.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        (it.name.startsWith("assemble") || it.name.startsWith("bundle")) &&
            it.name.endsWith("Release")
    }
    if (buildsRelease && keystoreProperties.isEmpty &&
        System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") == null
    ) {
        throw GradleException(
            "android/key.properties is missing, so this release build would be " +
                "debug-signed. See DEPLOYMENT.md (Mobile) or set " +
                "ALLOW_DEBUG_SIGNED_RELEASE=1."
        )
    }
}
