import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pagla.chat"
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

    // 🎯 হৃদয় ভাই, আপনার নতুন চাবির কনফিগারেশন এখানে সেট করা হলো
    signingConfigs {
        create("release") {
            storeFile = file("upload-keystore.jks") 
            storePassword = "pagla1234"
            keyAlias = "pagla-upload"
            keyPassword = "pagla1234"
        }
    }

    defaultConfig {
        applicationId = "com.pagla.chat"
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        
        // 🎯 গুগল প্লে কনসোলের এরর ফিক্স করার জন্য নতুন নম্বর দেওয়া হলো
        versionCode = 7
        versionName = "1.0.3"
        
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // 🎯 এখানে আপনার আসল চাবি "release" কানেক্ট করে দেওয়া হলো
            signingConfig = signingConfigs.getByName("release")
            
            // 🎯 কোটলিন ফাইলের সঠিক নিয়ম অনুযায়ী সেফটি লক অন করা হলো
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// সাব-প্রোজেক্টগুলোর (যেমন gallery_saver) JVM Target কনф্লিক্ট মেটানোর জন্য
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_1_8)
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}