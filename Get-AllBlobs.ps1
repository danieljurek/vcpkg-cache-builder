param(
    $AccountName,
    $ContainerName
)

$allBlobs = @()
$marker = ''

while($true) {
    $blobResult = az storage blob list `
        --account-name $AccountName `
        --container-name $ContainerName `
        --num-results 5000 `
        --marker "$marker" 2>&1

    # Stderr has the marker
    $markerOutput = $blobResult.Where({ $_ -is [System.Management.Automation.ErrorRecord]})
    
    # Normal output has the 
    $blobs = $blobResult.Where({ $_ -isnot [System.Management.Automation.ErrorRecord]}) `
        | ConvertFrom-Json -AsHashtable

    $allBlobs += $blobs

    if (!$markerOutput) { 
        # No next marker, quit
        break
    }

    # Example output -

    # WARNING: Next Marker:
    # WARNING: <marker>

    # Fetches <marker> from the output
    $marker = ($markerOutput[1] -split ' ')[1]

    if (!$marker) { 
        # No next marker, quit
        break
    }
}

return $allBlobs