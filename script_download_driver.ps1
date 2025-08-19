# Path to your MSI
$installerPath = ".\msoledbsql.msi"

# Check if the file exists
if (-Not (Test-Path $installerPath)) {
    Write-Error "Installer not found at $installerPath"
    exit 1
}

# Uninstall any existing OLE DB drivers (optional)
Write-Output "Checking for existing OLE DB drivers to uninstall..."
$existingDrivers = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*OLE DB*" }

foreach ($driver in $existingDrivers) {
    Write-Output "Uninstalling $($driver.Name)..."
    $driver.Uninstall() | Out-Null
}

Write-Output "Starting silent installation of OLE DB driver..."

# Install MSI silently with license acceptance
$arguments = "/i `"$installerPath`" /qn /norestart IACCEPTMSOLEDBSQLLICENSETERMS=YES ADDLOCAL=ALL"

$process = Start-Process -FilePath "msiexec.exe" `
    -ArgumentList $arguments `
    -Wait -PassThru

# Check exit code
switch ($process.ExitCode) {
    0 { Write-Output "Installation completed successfully." }
    3010 { Write-Output "Installation successful, but a reboot is required." }
    default { 
        Write-Error "Installation failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    }
}


# Verify installation by checking the registry for MSOLEDBSQL
Write-Output "Verifying OLE DB provider in the registry..."

$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Client OLE DB\MSOLEDBSQL",          # 64-bit
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\Client OLE DB\MSOLEDBSQL"  # 32-bit
)

$installed = $false

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Output "MSOLEDBSQL found at $path"
        $installed = $true
    }
}

if (-not $installed) {
    Write-Warning "MSOLEDBSQL provider not found in registry. Installation may have failed."
} else {
    Write-Output "MSOLEDBSQL provider installation verified."
}

# Optional: double-check via ADODB provider enumeration
try {
    $connection = New-Object -ComObject ADODB.Connection
    $providers = $connection.Provider
    if ($providers -match "MSOLEDBSQL") {
        Write-Output "MSOLEDBSQL provider is available via ADODB."
    } else {
        Write-Warning "MSOLEDBSQL provider not found in ADODB list."
    }
} catch {
    Write-Warning "Could not enumerate ADODB providers."
}


