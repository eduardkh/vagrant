# MILESTONE 4: resolve edited plugin pins in staging and update the local lock.
# No live plugins are changed here. Deploy separately with milestone-4.ps1.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Invoke-Vagrant {
    $commandOutput = @(& vagrant @args)
    if ($LASTEXITCODE -ne 0) {
        $commandOutput | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
        throw "Vagrant failed: $($args -join ' ')"
    }
    $commandOutput
}

$manifestPath = Join-Path $PSScriptRoot 'provision/plugins/plugins.txt'
$manifestLines = @(Get-Content -LiteralPath $manifestPath)
$requested = @{}
foreach ($manifestLine in $manifestLines) {
    $entry = $manifestLine.Trim()
    if (-not $entry -or $entry.StartsWith('#')) { continue }
    if ($entry -notmatch '^([A-Za-z0-9_.-]+):([A-Za-z0-9_.+-]+)$') {
        throw "Expected plugin-id:pinned-version, got: $entry"
    }
    $pluginId, $pluginVersion = $Matches[1], $Matches[2]
    if ($pluginVersion -in @('latest', 'experimental') -or $requested.ContainsKey($pluginId)) {
        throw "Use one explicit version per plugin: $entry"
    }
    $requested[$pluginId] = $pluginVersion
}
if ($requested.Count -eq 0) { throw 'Plugin manifest is empty' }
# Keep the cache hash independent of Windows editor line endings.
[IO.File]::WriteAllText($manifestPath, ($manifestLines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
$settings = Get-Content -Raw provision/ansible/group_vars/controller.json | ConvertFrom-Json
if ($settings.jenkins_version -notmatch '^[0-9.]+$' -or
    $settings.jenkins_plugin_manager_version -notmatch '^[0-9.]+$' -or
    $settings.jenkins_java_home -notmatch '^/[A-Za-z0-9/_.-]+$') {
    throw 'Unexpected controller version or Java path format'
}
$stage = "/var/cache/jenkins-plugin-manager/$($settings.jenkins_version)/$manifestHash"
$manager = "/opt/jenkins-plugin-manager/jenkins-plugin-manager-$($settings.jenkins_plugin_manager_version).jar"

Write-Host '[Milestone 4] Resolving requested pins and dependencies in staging'
Invoke-Vagrant upload $manifestPath /tmp/jenkins-plugins-request.txt jenkins-controller
$resolveCommand = "sudo bash /usr/local/lib/jenkins-lab/plugins/resolve.sh $($settings.jenkins_java_home)/bin/java $manager /tmp/jenkins-plugins-request.txt $stage $($settings.jenkins_version)"
$resolverOutput = @(Invoke-Vagrant ssh jenkins-controller -c $resolveCommand)
$resolverOutput | Where-Object { $_ -match '(?i)warning|vulnerab' } | ForEach-Object { Write-Warning $_ }

Write-Host '[Milestone 4] Recording resolved versions and verified archive checksums'
$inventoryCommand = "sudo /usr/bin/python3.9 /usr/local/lib/jenkins-lab/plugins/inventory.py $stage/plugins"
$resolvedJson = (Invoke-Vagrant ssh jenkins-controller -c $inventoryCommand) -join "`n"
$resolved = $resolvedJson | ConvertFrom-Json
$resolvedById = @{}
foreach ($pluginEntry in $resolved) {
    if ($pluginEntry.sha256 -notmatch '^[a-f0-9]{64}$' -or $pluginEntry.disabled) {
        throw "Invalid resolved plugin: $($pluginEntry.id)"
    }
    $resolvedById[$pluginEntry.id] = $pluginEntry
}
foreach ($pluginId in $requested.Keys) {
    if (-not $resolvedById.ContainsKey($pluginId) -or $resolvedById[$pluginId].version -ne $requested[$pluginId]) {
        throw "Resolver changed or omitted requested pin: $pluginId"
    }
}
# Add newly discovered dependency pins so later downloads select exact versions.
$dependencyPins = @($resolved | Where-Object { -not $requested.ContainsKey($_.id) } |
    ForEach-Object { "$($_.id):$($_.version)" } | Sort-Object)
if ($dependencyPins.Count -gt 0) {
    $manifestLines += '# Dependencies pinned by resolve-plugins.ps1'
    $manifestLines += $dependencyPins
    [IO.File]::WriteAllText($manifestPath, ($manifestLines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
}
# Replace the old lock only after successful resolution and pin validation.
$lockPath = Join-Path $PSScriptRoot 'provision/plugins/plugins.lock.json'
[IO.File]::WriteAllText($lockPath, "$resolvedJson`n", [Text.UTF8Encoding]::new($false))
Write-Host "[Milestone 4] Locked $($resolved.Count) plugins. Review the diff, then run .\milestone-4.ps1"
Write-Host "Resolver log: $stage/resolution.log (controller)"
