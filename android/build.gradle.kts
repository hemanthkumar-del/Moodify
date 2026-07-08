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

subprojects {
    val configureNamespace = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    setNamespace.invoke(android, project.group.toString())
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    tasks.configureEach {
        if (this.javaClass.name.contains("KotlinCompile") || this.javaClass.name.contains("KotlinJvmCompile")) {
            try {
                val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "11")
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    val configureAndroidSdk = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                setCompileSdk.invoke(android, 36)
            } catch (e: Exception) {
                try {
                    val compileSdkVersion = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType ?: Int::class.java)
                    compileSdkVersion.invoke(android, 36)
                } catch (e2: Exception) {
                    // Ignore
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
        configureAndroidSdk()
    } else {
        afterEvaluate {
            configureNamespace()
            configureAndroidSdk()
        }
    }
}
