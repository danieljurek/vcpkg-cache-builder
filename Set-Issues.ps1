param(
    $ReportFile='./download-report.json',
    $Repo='danieljurek/vcpkg-cache-builder', # TODO: can this be defaulted to an env var?
    $BuildUrl='missing'
)

$ISSUE_PREFIX = "[port downloadd failure]"
$portIssues = gh search issues `
    --repo $Repo `
    --state open `
    "$ISSUE_PREFIX" `
    --json number,title | ConvertFrom-Json -AsHashtable

$portIssuesHash = @{}
if ($portIssues) { 
    foreach ($item in $portIssues.GetEnumerator()) { 
        $portIssuesHash[$item.title] = $item.number
    }    
}

$report = Get-Content $ReportFile | ConvertFrom-Json -AsHashtable

foreach ($item in $report.GetEnumerator()) {
    $title = "$ISSUE_PREFIX $($item.Name)"

    $shaList = ($item.Value | ForEach-Object { "* $_" }) -join "`n"

    $issueBodyFile = New-TemporaryFile
    @"
Missing hashes identified for port $($item.Name)

Build: $BuildUrl

> [!NOTE]
> This list is updated by automation and may change as assets cycle out

$shaList

To fix: 
* If the SHA is not valid or the port has build problems
    * Add to ignore-ports.txt or ignore-hashes.txt 
* Ensure that the port downlaods successful which might include...
    * Ensuring that a required triplet is present (easiest)
    * Building the port to download the asset (needs build infrastructure)
    * Ensure features are properly configured

"@ | Set-Content $issueBodyFile

    if ($portIssuesHash.ContainsKey($title)) {
        $issueNumber = $portIssuesHash[$title]
        Write-Host "* $title - Found matching issue $issueNumber. Updating.."
        gh issue comment $issueNumber --repo $Repo --body-file $issueBodyFile
    } else {
        Write-Host "* $title - Creating new issue..."
        gh issue create --repo $Repo --title $title --body-file $issueBodyFile
    }
}