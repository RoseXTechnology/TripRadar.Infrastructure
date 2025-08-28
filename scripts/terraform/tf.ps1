# Terraform Helper Script for TripRadar Infrastructure
# This script simplifies Terraform operations across environments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [ValidateSet("plan", "apply", "destroy", "init", "validate", "fmt")]
    [string]$Action,

    [switch]$AutoApprove,
    [switch]$CompactWarnings
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define paths
$RootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$EnvPath = Join-Path $RootPath "environments\$Environment\app"
$TfvarsPath = Join-Path $RootPath "environments\$Environment\terraform.tfvars"

# Check if paths exist
if (-not (Test-Path $EnvPath)) {
    Write-Error "Environment directory not found: $EnvPath"
    exit 1
}

if (-not (Test-Path $TfvarsPath) -and $Action -ne "fmt" -and $Action -ne "validate") {
    Write-Error "Terraform variables file not found: $TfvarsPath"
    exit 1
}

# Navigate to environment directory
Write-Host "🔄 Navigating to environment: $Environment" -ForegroundColor Cyan
Set-Location $EnvPath

# Build terraform command
$tfCommand = "terraform $Action"

# Add var-file for plan/apply/destroy/init
if ($Action -in @("plan", "apply", "destroy", "init")) {
    $relativeTfvarsPath = "..\..\..\environments\$Environment\terraform.tfvars"
    $tfCommand += " -var-file=`"$relativeTfvarsPath`""
}

# Add flags
if ($AutoApprove -and $Action -eq "apply") {
    $tfCommand += " -auto-approve"
}

if ($CompactWarnings) {
    $tfCommand += " -compact-warnings"
}

# Display command
Write-Host "🚀 Executing: $tfCommand" -ForegroundColor Green
Write-Host "📍 In directory: $(Get-Location)" -ForegroundColor Yellow

# Execute command
try {
    Invoke-Expression $tfCommand
    Write-Host "✅ Command completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Command failed: $($_.Exception.Message)"
    exit 1
}
