$ErrorActionPreference = "Stop"

# Define paths and URLs
$installerUrl = "https://go.microsoft.com/fwlink/?linkid=829576"
$installerName = "x64_17.0.221.0_SQL_AS_OLEDB.msi"
$installerPath = Join-Path $env:TEMP $installerName
$logFile = Join-Path $env:TEMP "msolap_install.log"

# Download the installer if it doesn't exist
if (-not (Test-Path $installerPath)) {
    Write-Output "Downloading MSOLAP installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    Unblock-File -Path $installerPath
}

# Install MSOLAP silently
Write-Output "Installing MSOLAP provider..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart /log `"$logFile`"" -Wait -PassThru

# Verify installation by checking the registry
$registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSOLEDBSQL"
if (Test-Path $registryPath) {
    Write-Output "MSOLAP provider installed successfully."
} else {
    Write-Error "MSOLAP provider not found in registry. Installation may have failed."
    exit 1
}


Write-Output "OLE DB driver installation script completed."


