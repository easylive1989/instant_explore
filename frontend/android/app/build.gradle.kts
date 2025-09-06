import java.io.FileInputStream
import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.paulchwu.instantexplore"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.paulchwu.instantexplore"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        val dartEnvironmentVariables = mutableMapOf<String, String>()
        if (project.hasProperty("dart-defines")) {
            val dartDefines = project.property("dart-defines") as String
            dartDefines.split(",").forEach { entry ->
                val decodedEntry = String(Base64.getDecoder().decode(entry))
                val pair = decodedEntry.split("=")
                if (pair.size >= 2) {
                    dartEnvironmentVariables[pair[0]] = pair[1]
                }
            }
        }

        
        // Support for dart-define environment variables
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = dartEnvironmentVariables["GOOGLE_MAPS_API_KEY"] ?: ""
        
        // Patrol configuration for E2E testing
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    signingConfigs {
        getByName("debug") {
            keyAlias = keystoreProperties["debugKeyAlias"] as String? ?: "androiddebugkey"
            keyPassword = keystoreProperties["debugKeyPassword"] as String? ?: "android"
            storeFile = file(keystoreProperties["debugStoreFile"] as String? ?: "../debug.keystore")
            storePassword = keystoreProperties["debugStorePassword"] as String? ?: "android"
        }
        create("release") {
            keyAlias = keystoreProperties["releaseKeyAlias"] as String
            keyPassword = keystoreProperties["releaseKeyPassword"] as String
            storeFile = keystoreProperties["releaseStoreFile"]?.let { file(it) }
            storePassword = keystoreProperties["releaseStorePassword"] as String
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
        animationsDisabled = true
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.0")
    androidTestUtil("androidx.test:orchestrator:1.4.2")
}
