import org.gradle.api.Action
import org.gradle.api.Plugin
import org.gradle.api.artifacts.ArtifactRepositoryContainer
import org.gradle.api.artifacts.dsl.RepositoryHandler
import org.gradle.api.artifacts.repositories.MavenArtifactRepository
import org.gradle.api.invocation.Gradle

apply<RepositoryMirrorPlugin>()

class RepositoryMirrorPlugin : Plugin<Gradle> {
    override fun apply(gradle: Gradle) {
        val centralMirror = "https://maven.aliyun.com/repository/public"
        val pluginMirror = "https://maven.aliyun.com/repository/gradle-plugin"

        fun rewriteRepos(repos: RepositoryHandler) {
            repos.withType(MavenArtifactRepository::class.java).configureEach(
                Action {
                    val repoUrl = url.toString()
                    when (name) {
                        ArtifactRepositoryContainer.DEFAULT_MAVEN_CENTRAL_REPO_NAME -> setUrl(centralMirror)
                        "Gradle Central Plugin Repository" -> setUrl(pluginMirror)
                        else -> {
                            if (repoUrl.contains("repo.maven.apache.org")) setUrl(centralMirror)
                            if (repoUrl.contains("plugins.gradle.org")) setUrl(pluginMirror)
                        }
                    }
                },
            )
        }

        gradle.beforeSettings {
            rewriteRepos(buildscript.repositories)
            rewriteRepos(pluginManagement.repositories)
        }
        gradle.settingsEvaluated {
            rewriteRepos(dependencyResolutionManagement.repositories)
        }
        gradle.beforeProject {
            rewriteRepos(buildscript.repositories)
        }
        gradle.afterProject {
            rewriteRepos(repositories)
        }
    }
}
