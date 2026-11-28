# MILESTONE 4: copy local plugin pins and automation, then configure controller.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
& vagrant provision jenkins-controller --provision-with 'milestone2-directory,milestone2-files'
if ($LASTEXITCODE -ne 0) { throw 'Could not refresh controller provisioning files' }
& vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-4.sh'
if ($LASTEXITCODE -ne 0) { throw 'Milestone 4 failed' }
