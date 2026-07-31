import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Nënshkrimi i lëshimit. `key.properties` dhe `.jks` janë të gitignore-uara dhe
// rrinë vetëm te makina që ndërton (te CI-ja i shkruan puna «Vendos çelësin»).
//
// !! Çelësi `spacechess-upload.jks` është KOPJE E VETME te spacecode-brain. Nëse
//    humbet, ky aplikacion nuk përditësohet dot më kurrë: Android-i refuzon një
//    paketë të nënshkruar me çelës tjetër, dhe Play-i do të donte listim të ri.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "tech.spacecode.chess"
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
        applicationId = "tech.spacecode.chess"
        minSdk = 24
        // 🚨 Play kërkon API 35 për çdo ngarkim të ri që nga 31 gushti 2025,
        // dhe **API 36 që nga 31 gushti 2026**. Me një numër më të ulët
        // ngarkimi refuzohet te dera, para se ta shohë njeri.
        // Ngritur 35 → 36 më 2026-07-31: testimi i mbyllur zgjat 14 ditë dhe
        // publikimi bie pas afatit, pra çdo AAB i ri duhet të jetë tashmë 36.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.getProperty("storeFile") != null) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Pa `key.properties` bie prapa te çelësi i debug-ut, që e mban
            // `flutter run --release` të punueshëm lokalisht — por një AAB i
            // tillë refuzohet nga Play Console, ndaj CI-ja e kontrollon veçmas.
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
