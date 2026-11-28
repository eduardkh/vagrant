// MILESTONE 4: force English UI without changing authentication or user accounts.
// These language settings can move to JCasC in milestone 5.
import groovy.json.JsonOutput
import hudson.plugins.locale.PluginImpl
import jenkins.model.Jenkins

def controller = Jenkins.get()
def locale = PluginImpl.get()
locale.setSystemLocale('en')
locale.setIgnoreAcceptLanguage(true)
locale.setAllowUserPreferences(false)
locale.save()

// Public plugin metadata only: no credentials, tokens, jobs or user data.
def manager = controller.pluginManager
def report = [
    plugins: manager.plugins.collect { [id: it.shortName, version: it.version, active: it.active] },
    failed: manager.failedPlugins.collect { it.name },
    locale: [language: locale.systemLocale, ignoreBrowser: locale.ignoreAcceptLanguage,
             allowUserPreferences: locale.allowUserPreferences]
]
new File(controller.rootDir, 'milestone-4-plugins.json').text =
    JsonOutput.prettyPrint(JsonOutput.toJson(report))
