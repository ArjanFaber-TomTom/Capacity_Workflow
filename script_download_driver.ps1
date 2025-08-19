# Path to your MSI
$installerPath = ".\msoledbsql.msi"

# Check if the file exists
if (-Not (Test-Path $installerPath)) {
    Write-Error "Installer not found at $installerPath"
    exit 1
}

# Uninstall any existing OLE DB drivers
Write-Output "Checking for existing OLE DB drivers to uninstall..."
$existingDrivers = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*OLE DB*" }

foreach ($driver in $existingDrivers) {
    Write-Output "Uninstalling $($driver.Name)..."
    $driver.Uninstall()
}

Write-Output "Starting installation of OLE DB driver..."

# Install MSI silently
$process = Start-Process -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$installerPath`" /quiet /norestart" `
    -Wait -PassThru

# Check exit code
if ($process.ExitCode -eq 0) {
    Write-Output "Installation completed successfully."
} elseif ($process.ExitCode -eq 3010) {
    Write-Output "Installation successful, but a reboot is required."
} else {
    Write-Error "Installation failed with exit code $($process.ExitCode)"
    exit $process.ExitCode
}

# Verify installation by checking OLE DB providers
Write-Output "Verifying OLE DB provider..."
$connection = New-Object -ComObject ADODB.Connection
try {
    $providers = $connection.Provider
    if ($providers -match "MSOLEDBSQL") {
        Write-Output "MSOLEDBSQL provider is installed and available."
    } else {
        Write-Warning "MSOLEDBSQL provider not found in ADODB list."
    }
} catch {
    Write-Warning "Could not enumerate ADODB providers. The driver might not be installed correctly."
}



