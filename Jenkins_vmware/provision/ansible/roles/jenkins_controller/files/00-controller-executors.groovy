// MILESTONE 3: no build execution on the controller. Keep setup security intact.
import jenkins.model.Jenkins

def controller = Jenkins.get()
controller.setNumExecutors(0)
controller.save()
