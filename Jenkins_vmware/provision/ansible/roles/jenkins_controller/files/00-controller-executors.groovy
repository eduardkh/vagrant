// MILESTONE 3: no build execution on the controller. Keep setup security intact.
import jenkins.model.Jenkins

// Bootstrap fallback only; JCasC owns this setting once milestone 5 is enabled.
if (!System.getenv('CASC_JENKINS_CONFIG')) {
    def controller = Jenkins.get()
    controller.setNumExecutors(0)
    controller.save()
}
