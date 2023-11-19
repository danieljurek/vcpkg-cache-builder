param(
    $AccountName,
    $ContainerName
)

$allBlobs = ."$PSScriptRoot/Get-AllBlobs.ps1" `
    -AccountName $AccountName `
    -ContainerName $ContainerName

$blobHash = @{}
foreach($blob in $allBlobs) {
    $blobHash[$blob.name] = $blob
}

Write-Host "Found $($blobHash.Count) blobs in $ContainerName"

# Clone vcpkg
# TODO: Shallow clone, specify commitish from parameter
git clone https://github.com/microsoft/vcpkg.git | Out-Null

Push-Location vcpkg
$commitish = git rev-parse HEAD
Write-Host "Current vcpkg commitish: $commitish"
Pop-Location

$allShas = @{}

$portFiles = Get-ChildItem vcpkg/ports -File -Recurse

# Use regex to extract SHA512 from text files
foreach ($file in $portFiles) { 
    foreach ($line in Get-Content $file) { 
        if ($line -match '[a-fA-F0-9]{128}') { 
            foreach ($match in $matches.Values) { 
                if ($allShas.ContainsKey($match)) { 
                    $allShas[$match] += @($file)
                } else { 
                    $allShas[$match] = @($file)
                }
            }
        }
    }
}

Write-Host "Found $($allShas.Count) unique SHA512 hashes in vcpkg/ports"

$missingShas = @()
foreach ($sha512 in $allShas.Keys) { 
    if (!$blobHash.ContainsKey($sha512)) { 
        $missingShas += $sha512
    }
}

$portNames = @{}
$separator = [IO.Path]::DirectorySeparatorChar
foreach ($sha512 in $missingShas) { 
    # Extract port name, it's the first directory after vcpkg/ports/<portname>/possible/other/dirs
    $directories = $allShas[$sha512].Directory.FullName.Split($separator)
    for ($i = $directories.Length - 2; $i -gt 0; $i--) { 
        if ($directories[$i] -eq "ports") { 
            $portNames[$directories[$i + 1]] = $true
            break
        }
    }
}

Write-Host "Found $($portNames.Count) ports with missing blobs"

return $portNames.Keys | Sort-Object
