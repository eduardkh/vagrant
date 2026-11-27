# MILESTONE 3: refresh controller files, then run the annotated guest script.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& vagrant provision jenkins-controller --provision-with 'milestone2-directory,milestone2-files'
if ($LASTEXITCODE -ne 0) { throw 'Could not refresh controller provisioning files' }
& vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-3.sh'
if ($LASTEXITCODE -ne 0) { throw 'Milestone 3 failed' }
