plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.bus_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.bus_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // ✅ Hardcoded API key goes here
        resValue("string", "google_maps_key", "AIzaSyAMXlmK_FnSVjKr6Aap4x2e4T8mIKv2eJI")
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
