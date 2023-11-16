#!/usr/bin/env pwsh
param(
    $Triplets = 'x64-linux',
    $OutFile = '',
    $First = 0
)
function vcpkgDownload($port, $triplet) {
    try {
        Write-Host "vcpkg/vcpkg install `"$($port):$($triplet)`" --only-downloads ..." 
        $logs = vcpkg/vcpkg install `
            "$($port):$($triplet)" `
            --only-downloads
    
        if ($LASTEXITCODE) {
            Write-Host "Failed"
        } else {
            Write-Host "Succeeded"
        }
    
        return @{ Port = $port; Triplet = $triplet; Logs = $logs; ExitCode = $LASTEXITCODE }
   
    } finally {
        # Build never completes when using `--only-downloads` so perform 
        # manual cleaning
        Push-Location vcpkg
        git clean -xdf buildtrees/ installed/ packages/ downloads/
        Pop-Location
    }

}

# Clone vcpkg
# TODO: Shallow clone, specify commitish from parameter
git clone https://github.com/microsoft/vcpkg.git
Push-Location vcpkg
$commitish = git rev-parse HEAD
Pop-Location 
Write-Host "Current vcpkg commitish: $commitish"


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
foreach ($port in $ports.Keys | Sort-Object) {
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
    # TODO: If a task is canceled can we trap and try to write the log? 
    # Otherwise, write a log file for each port.
    $results | ConvertTo-Json | Set-Content $OutFile
}

Write-Host "Summary: "
Write-host "Ports: $($ports.Keys.Count)"
Write-Host "Port * Triplets Processed: $($results.Count)"
Write-Host "Succeeded: $($results.Where({$_.ExitCode -eq 0}).Count)"
Write-Host "Failed: $($results.Where({$_.ExitCode -ne 0}).Count)"

# Ensure that the last exit code is 0 or CI will think the job failed
exit 0