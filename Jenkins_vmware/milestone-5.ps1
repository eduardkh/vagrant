# MILESTONE 5: refresh controller files and run the annotated JCasC workflow.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& vagrant provision jenkins-controller --provision-with 'milestone2-directory,milestone2-files'
if ($LASTEXITCODE -ne 0) { throw 'Could not refresh controller provisioning files' }
& vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-5.sh'
if ($LASTEXITCODE -ne 0) { throw 'Milestone 5 failed' }
