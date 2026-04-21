allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// অটোমেটিক প্যাকেজ এরর ফিক্স করার নতুন কোড (Kotlin DSL format)
subprojects {
    val subproject = this
    if (subproject.name != "app") {
        plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
            val android = subproject.extensions.getByType<com.android.build.gradle.BaseExtension>()
            if (android.namespace == null) {
                android.namespace = subproject.group.toString()
            }
        }
    }
}