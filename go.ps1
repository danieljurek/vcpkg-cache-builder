#!/usr/bin/env pwsh
param(
    $Triplets = 'x64-linux',
    $OutFile = '',
    $First = 0
)
function vcpkgDownload($port, $triplet) {
    Write-Host "vcpkg/vcpkg install `"$($port):$($triplet)`" --only-downloads ..." 
    $logs = vcpkg/vcpkg install `
        "$($port):$($triplet)" `
        --only-downloads `
        --clean-downloads-after-build

    if ($LASTEXITCODE) {
        Write-Host "Failed"
    } else {
        Write-Host "Succeeded"
    }

    return @{ Port = $port; Triplet = $triplet; Logs = $logs; ExitCode = $LASTEXITCODE }
}

# Clone vcpkg 
git clone https://github.com/microsoft/vcpkg.git

# Install vcpkg
if ($IsWindows) { 
    .\vcpkg\bootstrap-vcpkg.bat
} else {
    ./vcpkg/bootstrap-vcpkg.sh
}

# List vcpkg ports
$ports = ./vcpkg/vcpkg search --x-json | ConvertFrom-Json -AsHashtable

Write-Host "Total ports $($ports.Count)"

# Process ports
$splitTriplets = $Triplets -split ','
$results = @()
$processed = 0
foreach ($port in $ports.Keys) {
    $processed++
    Write-Host "[$(($processed/$ports.Keys.Count).ToString('P'))] Port: $($targetPort.package_name)"
    $targetPort = $ports[$port]

    foreach ($triplet in $splitTriplets) { 
        $result = vcpkgDownload -port $targetPort.package_name -triplet $triplet
        $results += $result
    }

    if ($First -and $processed -ge $First) { 
        Write-Host "Processed first $processed ports, exiting"
        break
    }
}

if ($OutFile) {
    $results | ConvertTo-Json | Set-Content $OutFile
}

Write-Host "Summary: "
Write-host "Ports: $($ports.Keys.Count)"
Write-Host "Port * Triplets Processed: $($results.Count)"
Write-Host "Succeeded: $($results.Where({$_.ExitCode -eq 0}).Count)"
Write-Host "Failed: $($results.Where({$_.ExitCode -ne 0}).Count)"
