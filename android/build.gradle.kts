allprojects {
    repositories {
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
    }
}

subprojects {
    // flutter_local_notifications requests AGP 8.6.0 in its buildscript.
    // Some environments fail to resolve that exact artifact, while the app already
    // uses AGP 8.9.1. Align plugin classpath/transitives to the project's AGP.
    buildscript {
        repositories {
            maven(url = "https://maven.aliyun.com/repository/google")
            maven(url = "https://maven.aliyun.com/repository/public")
            google()
            mavenCentral()
        }
        configurations.matching { it.name == "classpath" }.all {
            resolutionStrategy.eachDependency {
                if (requested.group == "com.android.tools.build" &&
                    requested.name == "gradle" &&
                    requested.version == "8.6.0"
                ) {
                    useVersion("8.9.1")
                    because("Align plugin AGP with root project")
                }
                if (requested.group == "com.android.tools.build" &&
                    requested.name == "builder" &&
                    requested.version == "8.6.0"
                ) {
                    useVersion("8.9.1")
                    because("Avoid missing builder-8.6.0 artifact")
                }
            }
        }
    }
}

subprojects {
    configurations.all {
        resolutionStrategy {
            // Nuclear solution: Force all camera dependencies to use available version
            eachDependency {
                if (requested.group == "androidx.camera") {
                    when (requested.version) {
                        "1.3.3" -> {
                            useVersion("1.3.4")
                            because("Version 1.3.3 not available, using 1.3.4")
                        }
                    }
                }
            }
            // Force all camera libraries to compatible versions
            force("androidx.camera:camera-core:1.3.4")
            force("androidx.camera:camera-camera2:1.3.4")
            force("androidx.camera:camera-lifecycle:1.3.4")
            force("androidx.camera:camera-view:1.3.4")
        }
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
    
    // Nuclear solution: Apply resolution strategy to ALL subprojects (including plugins)
    afterEvaluate {
        configurations.all {
            resolutionStrategy {
                // Force all camera dependencies to use available version
                eachDependency {
                    if (requested.group == "androidx.camera") {
                        when (requested.version) {
                            "1.3.3" -> {
                                useVersion("1.3.4")
                                because("Version 1.3.3 not available, using 1.3.4")
                            }
                        }
                    }
                }
                // Force all camera libraries to compatible versions
                force("androidx.camera:camera-core:1.3.4")
                force("androidx.camera:camera-camera2:1.3.4")
                force("androidx.camera:camera-lifecycle:1.3.4")
                force("androidx.camera:camera-view:1.3.4")
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
