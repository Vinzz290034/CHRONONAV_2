// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Defines the version of the Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.1.1") 
        // 🟢 FIX 1 (Kotlin Syntax): Define the Kotlin version property
        // Note: The actual Kotlin version is often set in the settings.gradle.kts file,
        // but defining it directly here works as well for simple projects.
        // Using '1.9.22' as the stable version.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

// 🟢 FIX 2 (Kotlin Syntax): Define properties directly in the project build script
// This replaces the Groovy 'ext.kotlin_version'
// The actual variable for the version defined above is local to the buildscript block.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory configuration (The syntax for this part was mostly correct)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}