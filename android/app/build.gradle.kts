import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pagla_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Core Library Desugaring এনাবল করা হলো
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_1_8)
        }
    }

    defaultConfig {
        applicationId = "com.example.pagla_chat"
        // যদি notifications এ সমস্যা করে তবে সরাসরি ২১ লিখে দিতে পারেন
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// সাব-প্রোজেক্টগুলোর (যেমন gallery_saver) JVM Target কনফ্লিক্ট মেটানোর জন্য
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_1_8)
                    // প্লাগইনগুলোকে জোর করে ১.৮ এ নামিয়ে আনার কমান্ড
                    freeCompilerArgs.add("-Xjdk-release=1.8")
                }
            }
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // এই লাইব্রেরিটি Java 8+ এর নতুন ফিচারগুলো সাপোর্ট করতে সাহায্য করে
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
