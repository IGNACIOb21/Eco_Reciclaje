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

// mapbox_maps_flutter 3.0 solo aplica 'kotlin-android' con AGP < 9 y en AGP 9
// cuenta con el Kotlin integrado, que este proyecto tiene apagado
// (android.builtInKotlin=false en gradle.properties). Sin esto su bloque
// kotlin {} no existe y el build falla.
subprojects {
    if (name == "mapbox_maps_flutter_mobile") {
        pluginManager.withPlugin("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")
        }
    }
}

// tflite_flutter 0.12 compila Java para la JVM 11, pero su Kotlin toma la del
// JDK instalado y Gradle rechaza la diferencia: se deja Kotlin también en 11.
subprojects {
    if (name == "tflite_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
