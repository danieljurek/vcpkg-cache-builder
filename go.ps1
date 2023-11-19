#!/usr/bin/env pwsh
param(
    $Ports = @(),
    $Triplets = 'x64-linux',
    $OutFile = '',
    $First = 0,
    $Parallel = 2
)

function vcpkgDownload($port, $triplet) {
    
    $originalLocation = Get-Location
    try {
        Set-Location ./vcpkg 
        $setupDuration = Measure-Command { 
            $worktreeLocation = "../worktrees/$triplet/$($port.Replace('[', '_').Replace(']', '_'))"
            git worktree add $worktreeLocation 2>&1 | Out-Null
    
            if ($IsWindows) { 
                Copy-Item ./vcpkg.exe $worktreeLocation/vcpkg.exe
            } else { 
                Copy-Item ./vcpkg $worktreeLocation/vcpkg
            }
    
        }
        Set-Location $worktreeLocation

        $logs = @()
        $duration = Measure-Command {
            $logs = ./vcpkg install "$($port):$($triplet)" --only-downloads
         }

        $logLine = "vcpkg install `"$($port):$($triplet)`" --only-downloads" 
        if ($LASTEXITCODE) {
            $logLine += " Failed"
        } else {
            $logLine += " Succeeded"
        }
        $logLine += " (Vcpkg time: $($duration.TotalSeconds)s, Setup time: $($setupDuration.TotalSeconds)s)"
        Write-host $logLine

        return @{ 
            Port = $port; 
            Triplet = $triplet; 
            Logs = $logs; 
            ExitCode = $LASTEXITCODE; 
            VcpkgSeconds = $duration.TotalSeconds;
            SetupSeconds = $setupDuration.TotalSeconds;
        }
   
    } finally {
        Set-Location $originalLocation/vcpkg
        git worktree remove $worktreeLocation 2>&1 | Write-Host

        Set-Location $originalLocation
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

$stringVcpkgDownload = ${function:vcpkgDownload}.ToString()
$results = $toRun | ForEach-Object -ThrottleLimit $Parallel -Parallel {
    # Workaround to enable function call in parallel block. The function could
    # also be put inline, but it's possible to argue that this is more readable.
    ${function:vcpkgDownload} = $using:stringVcpkgDownload
    vcpkgDownload -port $_.Port -triplet $_.Triplet
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
