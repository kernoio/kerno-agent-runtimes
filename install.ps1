# PowerShell installation script for Windows x64

# BEGIN - AUTO GENERATED DO NOT EDIT
$RUNTIME_RELEASE = "2025.11.14.11"
$AGENT_RELEASE = "2025.11.14.12"
$AGENT_ASSET_ID = "316423336"
$RUNTIME_ASSET_ID_WINDOWS_AMD64 = ""
# END - AUTO GENERATED DO NOT EDIT

# Override with latest dev pre-release assets if DEV=true
if ($env:DEV -eq "true") {
    Write-Host "Fetching latest-dev pre-release..."

    try {
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/tags/latest-dev" -ErrorAction Stop

        $RELEASE_ID = $releaseInfo.id
        $AGENT_RELEASE = $releaseInfo.tag_name

        Write-Host "Fetching assets for release $AGENT_RELEASE..."
        $assetsData = Invoke-RestMethod -Uri "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/$RELEASE_ID/assets" -ErrorAction Stop

        # Find asset IDs by name
        $agentAsset = $assetsData | Where-Object { $_.name -eq "kerno-agent.tar.gz" }
        $windowsAsset = $assetsData | Where-Object { $_.name -eq "custom-jre-windows-amd64.zip" }

        if ($agentAsset) {
            $AGENT_ASSET_ID = $agentAsset.id.ToString()
        }

        if ($windowsAsset) {
            $RUNTIME_ASSET_ID_WINDOWS_AMD64 = $windowsAsset.id.ToString()
            $RUNTIME_RELEASE = $AGENT_RELEASE
        }

        Write-Host "Clearing out old latest-dev builds"
        $devAgentPath = "$env:USERPROFILE\.kerno\assets\agent\latest-dev"
        $devRuntimePath = "$env:USERPROFILE\.kerno\assets\runtime\latest-dev"

        if (Test-Path $devAgentPath) {
            Remove-Item -Path $devAgentPath -Recurse -Force
        }
        if (Test-Path $devRuntimePath) {
            Remove-Item -Path $devRuntimePath -Recurse -Force
        }

        Write-Host "Using latest-dev pre-release assets (AGENT_RELEASE=$AGENT_RELEASE)"
    }
    catch {
        Write-Host "Error: Could not fetch latest-dev release. Ensure latest-dev pre-release exists"
        exit 1
    }
}

$PLATFORM = "windows-amd64"
$RUNTIME_ASSET_ID = $RUNTIME_ASSET_ID_WINDOWS_AMD64

Write-Host "Detected platform: $PLATFORM"
Write-Host "Using RUNTIME_ASSET_ID: $RUNTIME_ASSET_ID"

# Check if runtime is already installed
$RUNTIME_FINISHED_FILE = "$env:USERPROFILE\.kerno\assets\runtime\$RUNTIME_RELEASE\finished"
if (Test-Path $RUNTIME_FINISHED_FILE) {
    Write-Host "Runtime $RUNTIME_RELEASE already installed, skipping download."
}
else {
    Write-Host "Downloading runtime $RUNTIME_RELEASE..."

    # Create directories
    $runtimeDir = "$env:USERPROFILE\.kerno\assets\runtime\$RUNTIME_RELEASE"
    New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null

    $runtimeZip = "$runtimeDir\runtime.zip"

    try {
        $headers = @{
            "Accept" = "application/octet-stream"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        Invoke-WebRequest -Uri "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$RUNTIME_ASSET_ID" `
            -Headers $headers `
            -OutFile $runtimeZip `
            -ErrorAction Stop

        Write-Host "Extracting runtime..."
        Expand-Archive -Path $runtimeZip -DestinationPath $runtimeDir -Force

        Remove-Item $runtimeZip
        New-Item -ItemType File -Path $RUNTIME_FINISHED_FILE -Force | Out-Null
        Write-Host "Runtime installation completed successfully."
    }
    catch {
        Write-Host "Failed to download or extract runtime: $_"
        exit 1
    }
}

# Check if agent is already installed
$AGENT_FINISHED_FILE = "$env:USERPROFILE\.kerno\assets\agent\$AGENT_RELEASE\finished"

if (Test-Path $AGENT_FINISHED_FILE) {
    Write-Host "Agent $AGENT_RELEASE already installed, skipping download."
}
else {
    Write-Host "Downloading agent $AGENT_RELEASE..."

    $agentDir = "$env:USERPROFILE\.kerno\assets\agent\$AGENT_RELEASE"
    New-Item -ItemType Directory -Force -Path $agentDir | Out-Null

    $agentTarGz = "$agentDir\agent.tar.gz"

    try {
        $headers = @{
            "Accept" = "application/octet-stream"
            "X-GitHub-Api-Version" = "2022-11-28"
        }

        Invoke-WebRequest -Uri "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$AGENT_ASSET_ID" `
            -Headers $headers `
            -OutFile $agentTarGz `
            -ErrorAction Stop

        Write-Host "Extracting agent..."

        # Extract .tar.gz using tar (available in Windows 10 1803+ and Windows Server 2019+)
        $tarPath = "tar"
        if (Get-Command tar -ErrorAction SilentlyContinue) {
            & tar -xzf $agentTarGz -C $agentDir
            if ($LASTEXITCODE -ne 0) {
                throw "tar extraction failed"
            }
        }
        else {
            throw "tar command not found. Please ensure you're running Windows 10 (1803+) or Windows Server 2019+"
        }

        Remove-Item $agentTarGz
        New-Item -ItemType File -Path $AGENT_FINISHED_FILE -Force | Out-Null

        # Create startup.ps1 script
        $STARTUP_SCRIPT = "$agentDir\startup.ps1"

        $startupContent = @"
# Kerno Agent Startup Script

`$env:JAVA_HOME = "`$env:USERPROFILE\.kerno\assets\runtime\$RUNTIME_RELEASE\custom-jre"
& "`$env:USERPROFILE\.kerno\assets\agent\$AGENT_RELEASE\aicore-agent\bin\aicore-agent.bat"
"@

        Set-Content -Path $STARTUP_SCRIPT -Value $startupContent -Force
        Write-Host "Agent installation completed successfully."
    }
    catch {
        Write-Host "Failed to download or extract agent: $_"
        exit 1
    }
}

Write-Host "All installations completed successfully."
Write-Host "Kerno can be started up with: $env:USERPROFILE\.kerno\assets\agent\$AGENT_RELEASE\startup.ps1"
