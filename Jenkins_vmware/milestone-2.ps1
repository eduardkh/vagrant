# MILESTONE 2: Windows host entry point. All guest configuration is visible in
# provision/milestone-2.sh and its Ansible playbook. No private key is copied.
[CmdletBinding()]
param([switch]$ReenrollRebuiltAgent)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Invoke-Vagrant {
    & vagrant @args
    if ($LASTEXITCODE -ne 0) { throw "Vagrant failed: $($args -join ' ')" }
}

Write-Host '[Milestone 2] Copy the local provision directory to the controller'
Invoke-Vagrant validate
Invoke-Vagrant provision jenkins-controller --provision-with 'milestone2-directory,milestone2-files'
Invoke-Vagrant ssh jenkins-controller -c 'test -f /vagrant/milestone-2.sh'
Invoke-Vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-2.sh --prepare'

Write-Host '[Milestone 2] Enroll controller public key through trusted Vagrant SSH'
$publicKey = @(Invoke-Vagrant ssh jenkins-controller -c 'cat /home/vagrant/.ssh/jenkins_lab_ed25519.pub' |
    Where-Object { $_ -match '^ssh-ed25519 ' })
if ($publicKey.Count -ne 1) { throw 'Expected exactly one controller public key' }
$stateDir = Join-Path $PSScriptRoot '.vagrant/milestone2'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$publicKeyFile = Join-Path $stateDir 'controller.pub'
[IO.File]::WriteAllText($publicKeyFile, "$($publicKey[0].Trim())`n", [Text.Encoding]::ASCII)
Invoke-Vagrant upload $publicKeyFile /tmp/jenkins-controller.pub jenkins-agent-linux
Invoke-Vagrant upload provision/enroll-agent.sh /tmp/jenkins-enroll-agent.sh jenkins-agent-linux
Invoke-Vagrant ssh jenkins-agent-linux -c 'bash /tmp/jenkins-enroll-agent.sh /tmp/jenkins-controller.pub'

Write-Host '[Milestone 2] Pin agent host identity read through trusted Vagrant SSH'
$hostKey = @(Invoke-Vagrant ssh jenkins-agent-linux -c 'cat /etc/ssh/ssh_host_ed25519_key.pub' |
    Where-Object { $_ -match '^ssh-ed25519 ' })
if ($hostKey.Count -ne 1) { throw 'Expected exactly one agent host public key' }
$fields = $hostKey[0].Trim() -split '\s+'
$knownHost = "jenkins-agent-linux $($fields[0]) $($fields[1])"
$runtimeDir = Join-Path $PSScriptRoot 'provision/.runtime'
New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
$pinFile = Join-Path $runtimeDir 'agent-known-hosts'
if ((Test-Path -LiteralPath $pinFile) -and ((Get-Content -Raw $pinFile).Trim() -ne $knownHost)) {
    if (-not $ReenrollRebuiltAgent) {
        throw 'Agent host key changed. After confirming a VM rebuild, rerun with -ReenrollRebuiltAgent to enroll its key through authenticated Vagrant SSH.'
    }
    Write-Host '[Milestone 2] Re-enrolling rebuilt agent using its Vagrant-authenticated host key'
}
[IO.File]::WriteAllText($pinFile, "$knownHost`n", [Text.Encoding]::ASCII)
Invoke-Vagrant ssh jenkins-controller -c 'install -d -m 0700 /vagrant/.runtime'
Invoke-Vagrant upload $pinFile /vagrant/.runtime/agent-known-hosts jenkins-controller
Invoke-Vagrant ssh jenkins-controller -c 'bash /vagrant/milestone-2.sh --configure'
Write-Host '[Milestone 2] Complete. Windows and Jenkins installation remain deferred.'
