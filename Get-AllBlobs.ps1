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
        --marker "`'$marker`'" `
        --show-next-marker
 
    if ($LASTEXITCODE) {
        $blobResult | Write-Host
        Write-Error "az storage blob list failed with exit code $LASTEXITCODE"
    }

    $blobs = $blobResult | ConvertFrom-Json -AsHashtable
    $allBlobs += $blobs.Where({ !$_.ContainsKey('nextMarker') })

    Write-Host "Found $($allBlobs.Count) blobs so far..."
    $marker = $blobs[-1].nextMarker

    if (!$marker) {
        break
    }
}

return $allBlobs