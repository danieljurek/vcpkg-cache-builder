#!/usr/bin/env pwsh



# Clone vcpkg 
gh repo clone microsoft/vcpkg

# Install vcpkg
if ($IsWindows) { 
    .\vcpkg\bootstrap-vcpkg.bat
} else {
    ./vcpkg/bootstrap-vcpkg.sh
}

# List vcpkg ports
$ports = ./vcpkg/vcpkg search --x-json | ConvertFrom-Json -AsHashtable