#!/usr/bin/env pwsh
param(
    $Ports = @(),
    $IgnorePorts = @(),
    $Triplets = 'x64-linux', # 'x64-linux,x64-uwp,x64-windows-static,x64-windows,x86-windows,arm64-windows',
    $OutFile = '',
    $First = 0,
    [switch] $Install
)

function vcpkgDownload($port, $triplet, $install) {
    # TODO: If running low on disk space, run git clean -xdf    
    try {
        Set-Location $PSScriptRoot/vcpkg 
        $logs = @()
        $extraParameters = '--only-downloads'
        if ($install) { 
            $extraParameters = ''
        }
        $portAndTriplet =  "$($port):$($triplet)" 
        $duration = Measure-Command {
            $logs = & ./vcpkg install $portAndTriplet --allow-unsupported $extraParameters
         }

        $logLine = "vcpkg install $portAndTriplet --allow-unsupported $extraParameters" 
        if ($LASTEXITCODE) {
            $logLine += " Failed"
        } else {
            $logLine += " Succeeded"
        }
        $logLine += " (Vcpkg time: $($duration.TotalSeconds)s)"
        Write-host $logLine
   
    } finally {

    }

    return @{ 
        Port = $port; 
        Triplet = $triplet; 
        Logs = $logs; 
        ExitCode = $LASTEXITCODE; 
        VcpkgSeconds = $duration.TotalSeconds;
    }
}

function getFeatures($port) { 
    $vcpkgJsonLocation = "./vcpkg/ports/$port/vcpkg.json"
    if (!(Test-Path $vcpkgJsonLocation)) { 
        return @()
    }

    $vcpkgSpec = Get-Content ./vcpkg/ports/$port/vcpkg.json `
        | ConvertFrom-Json -AsHashtable
    
    if ($vcpkgSpec.ContainsKey('features')) { 
        return $vcpkgSpec.features.Keys
    }

    return @()
}

# Clone vcpkg
# TODO: Shallow clone, specify commitish from parameter
git clone https://github.com/microsoft/vcpkg.git

Push-Location vcpkg
$commitish = git rev-parse HEAD
Write-Host "Current vcpkg commitish: $commitish"

if ($IsWindows) {
    .\bootstrap-vcpkg.bat
} else {
    ./bootstrap-vcpkg.sh
}
Pop-Location 


# List vcpkg ports
if (!$Ports) { 
    $Ports = (./vcpkg/vcpkg search --x-json | ConvertFrom-Json -AsHashtable).Keys | Sort-Object
}

if ($IgnorePorts) { 
    $Ports = $Ports | Where-Object { $IgnorePorts -notcontains $_ }
}

Write-Host "Total ports $($Ports.Count)"

# Process ports
$splitTriplets = $Triplets -split ','
$results = @()
$toRun = @()
$processed = 0
foreach ($port in $Ports) {
    $processed++

    foreach ($triplet in $splitTriplets) {
        $features = getFeatures $port

        if (!$features) { 
            $toRun += @{ Port = $port; Triplet = $triplet }
        } else { 
            foreach($feature in $features) { 
                $toRun += @{
                    Port = "$port[$feature]"; 
                    Triplet = $triplet 
                }
            }
        }
    }

    if ($First -and $processed -ge $First) { 
        Write-Host "Done queuing, only processing the first $First ports"
        break
    }
}

Write-Host "Ports to download: $($toRun.Count)"

$results = $toRun | ForEach-Object {
    vcpkgDownload -port $_.Port -triplet $_.Triplet -install $Install
}

if ($OutFile) {
    # TODO: If a task is canceled can we trap and try to write the log? 
    # Otherwise, write a log file for each port.
    $results | ConvertTo-Json | Set-Content $OutFile
}

Write-Host "Summary: "
Write-host "Ports: $($ports.Keys.Count)"
Write-Host "Port * Triplets Processed: $($toRun.Count)"
Write-Host "Succeeded: $($results.Where({$_.ExitCode -eq 0}).Count)"
Write-Host "Failed: $($results.Where({$_.ExitCode -ne 0}).Count)"

# Ensure that the last exit code is 0 or CI will think the job failed
exit 0
