#!/usr/bin/env pwsh
param(
    $Commitish = 'master',
    $Ports = @(),
    $IgnorePorts = @(),
    $Triplets = 'x64-linux',
    $First = 0,
    $CleanThresholdPercent = 0.10,
    [switch] $Install
)

function getPortName($port) {
    if ($port -match '(?<portName>.*)\[.*\]') {
        return $Matches['portName']
    }

    return $port
}

function vcpkgDownload($port, $triplet, $install) {
    
    try {
        $portFileName = getPortName $port
        $logDirectory = New-Item -ItemType Directory -Force -Path "$PSScriptRoot/logs/$triplet/$portFileName/"
        
        if (!(Test-Path  "$PSScriptRoot/logs/$triplet/$portFileName/")) { 
            Write-Error "Could not create folder -- $PSScriptRoot/logs/$triplet/$portFileName/"
            exit 1
        }
        Set-Location $PSScriptRoot/vcpkg 

        $extraParameters = '--only-downloads'
        if ($install) { 
            $extraParameters = ''
        }
        $portAndTriplet =  "$($port):$($triplet)" 
        Write-Host -NoNewline "vcpkg install $portAndTriplet --allow-unsupported $extraParameters`t"
        $duration = Measure-Command {
            & ./vcpkg install $portAndTriplet $extraParameters  --allow-unsupported 2>&1 > "$logDirectory/vcpkg.log"
         }

        if ($LASTEXITCODE) {
            Write-Host -NoNewline "Failed"
        } else {
            Write-Host -NoNewline "Succeeded"
        }
        Write-Host " (Vcpkg time: $(($duration.TotalSeconds).ToString('#.#s')))"

        $result = [ordered]@{ 
            Port = $port; 
            Triplet = $triplet; 
            ExitCode = $LASTEXITCODE; 
            VcpkgSeconds = $duration.TotalSeconds;
        }
        $result | ConvertTo-Json -Depth 100 | Set-Content $logDirectory/results.json
        return $result 
   
    } finally {
        # TODO: probably can eliminate this
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

function ensureDiskSpace {
    $disk = Get-PSDrive `
        | Where-Object { $_.CurrentLocation } `
        | Select-Object -First 1

    $diskFreePercent = $disk.Free / ($disk.Used + $disk.Free)
    if ($diskFreePercent -lt $CleanThresholdPercent) {
        Write-Host "Disk free space $($diskFreePercent.ToString('.##')) below threshold $($CleanThresholdPercent.ToString('.##'))... cleaning"
        Set-Location $PSScriptRoot/vcpkg
        git clean -Xdf ./buildtrees/ ./downloads/
    }
}

# Clone vcpkg
git clone https://github.com/microsoft/vcpkg.git --depth=1 --branch $Commitish

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
    # $Ports may be of the form portname[feature1,feature2]
    # But $IgnorePorts is of the form portname
    # Only use the "portname" part of "portname[feature1,feature2]"
    $portsToBuild = @()
    foreach ($port in $Ports) { 
        $portName = $port.Split('[')[0]
        if ($IgnorePorts -notcontains $portName) { 
            $portsToBuild += $port
        }
    }
    $Ports = $portsToBuild
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

        # Always add the port by itself with no features
        $toRun += @{ Port = $port; Triplet = $triplet }
        } if ($features) {
            $toRun += @{
                # TODO: Some features might be mutually exclusive
                Port = "$port[$($features -join ',')]"; 
                Triplet = $triplet 
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
    ensureDiskSpace
}

Write-Host "Summary: "
Write-host "Ports: $($Ports.Count)"
Write-Host "Port * Triplets Processed: $($toRun.Count)"
Write-Host "Succeeded: $($results.Where({$_.ExitCode -eq 0}).Count)"
Write-Host "Failed: $($results.Where({$_.ExitCode -ne 0}).Count)"

# Ensure that the last exit code is 0 or CI will think the job failed
exit 0
