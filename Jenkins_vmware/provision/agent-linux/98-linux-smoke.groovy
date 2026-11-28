// MILESTONE 6: owned smoke job and public runtime report; no credentials in output.
// Isolated JCasC validation copies only its read-only hook, never this job hook.
import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import hudson.model.Cause
import hudson.model.CauseAction
import hudson.model.ParametersAction
import hudson.model.ParametersDefinitionProperty
import hudson.model.StringParameterDefinition
import hudson.model.StringParameterValue
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.util.concurrent.TimeUnit
import java.util.logging.Logger
import jenkins.model.Jenkins
import jenkins.util.Timer
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def controller = Jenkins.get()
def specFile = new File('/etc/jenkins-lab/agent-linux/test-spec.json')
if (!specFile.exists() || !new File('/etc/jenkins-lab/features/linux-agent').exists()) {
    return
}
def spec = new JsonSlurper().parseText(specFile.text)
def pipelineFile = new File('/etc/jenkins-lab/agent-linux/Jenkinsfile')
def pipelineText = pipelineFile.text
def publicKey = new File('/etc/jenkins-lab/secrets/linux-agent-key.pub').text
def hostKey = new File('/etc/jenkins-lab/trust/linux-agent-host-key').text
def fingerprint = MessageDigest.getInstance('SHA-256')
    .digest((specFile.text + pipelineText + publicKey + hostKey).getBytes('UTF-8')).encodeHex().toString()
def marker = 'Managed by Jenkins lab milestone 6'
def job = controller.getItem(spec.smoke_job)
if (job != null && (!(job instanceof WorkflowJob) || !job.description?.startsWith(marker))) {
    throw new IllegalStateException('Smoke job name already belongs to an unmanaged job')
}
if (job == null) {
    job = controller.createProject(WorkflowJob.class, spec.smoke_job)
    job.setDescription(marker)
}
if (!(job.definition instanceof CpsFlowDefinition) || job.definition.script != pipelineText || !job.definition.sandbox) {
    job.setDefinition(new CpsFlowDefinition(pipelineText, true))
}
def parameter = job.getProperty(ParametersDefinitionProperty.class)?.getParameterDefinition('LAB_INPUTS')
if (parameter?.defaultParameterValue?.value != fingerprint) {
    job.addProperty(new ParametersDefinitionProperty(
        new StringParameterDefinition('LAB_INPUTS', fingerprint, 'Managed smoke-test input fingerprint')))
}
job.save()
def successfulInput = job.lastSuccessfulBuild?.getAction(ParametersAction.class)?.getParameter('LAB_INPUTS')?.value
if (successfulInput != fingerprint && !job.isBuilding() && !job.isInQueue()) {
    job.scheduleBuild2(0, new CauseAction(new Cause.RemoteCause('controller', 'Milestone 6 SSH validation')),
        new ParametersAction(new StringParameterValue('LAB_INPUTS', fingerprint)))
}

// A small heartbeat lets Ansible verify current connectivity without admin tokens
// or an anonymous API. It does not schedule further builds on each poll.
def logger = Logger.getLogger('jenkins.lab.milestone6')
Timer.get().scheduleWithFixedDelay({
    try {
        def computer = controller.getComputer(spec.name)
        def last = job.lastBuild
        def report = [
            updatedAt: System.currentTimeMillis(), node: spec.name,
            online: computer != null && computer.isOnline(),
            offlineReason: computer?.offlineCauseReason,
            controllerExecutors: controller.numExecutors,
            expectedInput: fingerprint, job: spec.smoke_job,
            buildNumber: last?.number, building: last?.isBuilding(),
            result: last?.result?.toString(),
            buildInput: last?.getAction(ParametersAction.class)?.getParameter('LAB_INPUTS')?.value
        ]
        def target = new File(controller.rootDir, 'milestone-6-linux-agent.json')
        def temporary = new File(controller.rootDir, 'milestone-6-linux-agent.json.tmp')
        temporary.text = JsonOutput.prettyPrint(JsonOutput.toJson(report))
        Files.move(temporary.toPath(), target.toPath(), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
    } catch (Exception error) {
        logger.warning('Linux smoke reporter failed: ' + error.class.simpleName)
    }
} as Runnable, 0, 5, TimeUnit.SECONDS)
