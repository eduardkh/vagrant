# MILESTONE 6: refresh visible provisioning files and run Linux-agent automation.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& vagrant provision jenkins-controller --provision-with 'milestone2-directory,milestone2-files'
if ($LASTEXITCODE -ne 0) { throw 'Could not refresh controller provisioning files' }
& vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-6.sh'
if ($LASTEXITCODE -ne 0) { throw 'Milestone 6 failed' }
