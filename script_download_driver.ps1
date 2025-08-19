# Path to your MSI
$installerPath = ".\msoledbsql.msi"

# Function to install Visual C++ Redistributables (x64 and x86)
function Install-VCRedist {
    Write-Output "Ensuring Microsoft Visual C++ Redistributables are installed..."
    
    $vcredistX64 = "$env:TEMP\vc_redist.x64.exe"
    $vcredistX86 = "$env:TEMP\vc_redist.x86.exe"

    # Download VC++ redistributables if not already present
    if (-not (Test-Path $vcredistX64)) {
        Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile $vcredistX64
    }
    if (-not (Test-Path $vcredistX86)) {
        Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x86.exe" -OutFile $vcredistX86
    }

    # Silent install VC++ redistributables
    Start-Process -FilePath $vcredistX64 -ArgumentList "/quiet /norestart" -Wait
    Start-Process -FilePath $vcredistX86 -ArgumentList "/quiet /norestart" -Wait

    Write-Output "Visual C++ Redistributables installation complete."
}

# Check if MSI exists
if (-Not (Test-Path $installerPath)) {
    Write-Error "Installer not found at $installerPath"
    exit 1
}

# Install VC++ Redistributables first
Install-VCRedist

# Uninstall any existing OLE DB drivers (optional)
Write-Output "Checking for existing OLE DB drivers to uninstall..."
$existingDrivers = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*OLE DB*" }
foreach ($driver in $existingDrivers) {
    Write-Output "Uninstalling $($driver.Name)..."
    $driver.Uninstall() | Out-Null
}

# Install MSI silently with license acceptance
Write-Output "Starting silent installation of OLE DB driver..."
$arguments = "/i `"$installerPath`" /qn /norestart IACCEPTMSOLEDBSQLLICENSETERMS=YES ADDLOCAL=ALL"
$process = Start-Process -FilePath "msiexec.exe" `
    -ArgumentList $arguments `
    -Wait -PassThru

# Check exit code
switch ($process.ExitCode) {
    0 { Write-Output "Installation completed successfully." }
    3010 { Write-Output "Installation successful, but a reboot is required (cannot reboot on hosted runner)." }
    default { 
        Write-Error "Installation failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    }
}

# Verify installation in the registry
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
        break
    }
}

if (-not $installed) {
    Write-Error "MSOLEDBSQL provider not found in registry. Installation may have failed."
    exit 1
} else {
    Write-Output "MSOLEDBSQL provider installation verified."
}

Write-Output "OLE DB driver installation script completed."

