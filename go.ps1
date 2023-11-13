#!/usr/bin/env pwsh



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

