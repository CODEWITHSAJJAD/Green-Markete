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

fun raisePluginCompileSdk(project: Project) {
    val androidExtension = project.extensions.findByName("android") ?: return
    val setter = androidExtension.javaClass.methods.firstOrNull {
        it.name == "setCompileSdkVersion" &&
            it.parameterCount == 1 &&
            (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                it.parameterTypes[0] == Int::class.javaObjectType)
    }
    if (setter != null) {
        setter.invoke(androidExtension, 36)
    }
}

subprojects {
    if (state.executed) {
        raisePluginCompileSdk(this)
    } else {
        afterEvaluate {
            raisePluginCompileSdk(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
