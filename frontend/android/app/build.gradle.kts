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

// Helper function to get property from keystore.properties or environment
fun getSigningProperty(key: String): String? {
    return keystoreProperties[key] as String? ?: System.getenv(key.toUpperCase())
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
        minSdk = 21
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
            keyAlias = getSigningProperty("debugKeyAlias") ?: "androiddebugkey"
            keyPassword = getSigningProperty("debugKeyPassword") ?: "android"
            storeFile = file(getSigningProperty("debugStoreFile") ?: "../debug.keystore")
            storePassword = getSigningProperty("debugStorePassword") ?: "android"
        }
        
        // Only create release signing config if we have the required properties
        val releaseKeyAlias = getSigningProperty("releaseKeyAlias")
        val releaseKeyPassword = getSigningProperty("releaseKeyPassword")
        val releaseStoreFile = getSigningProperty("releaseStoreFile")
        val releaseStorePassword = getSigningProperty("releaseStorePassword")
        
        if (releaseKeyAlias != null && releaseKeyPassword != null && 
            releaseStoreFile != null && releaseStorePassword != null) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = file(releaseStoreFile)
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Use release signing config if available, otherwise fall back to debug for CI
            signingConfig = if (signingConfigs.names.contains("release")) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
