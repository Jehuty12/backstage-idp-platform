param(
    [Parameter(Mandatory = $true)]
    [string]$InputSecret,

    [string]$OutputFile,

    [string]$CertFile = "$HOME\sealing-key.pub"
)

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  .\seal-secret.ps1 <input-secret.yaml> [output-sealedsecret.yaml] [public-cert.pem]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\seal-secret.ps1 .\secret.yaml .\sealed-secret.yaml $HOME\sealing-key.pub"
    Write-Host "  .\seal-secret.ps1 .\secret.yaml"
}

if (-not (Get-Command kubeseal -ErrorAction SilentlyContinue)) {
    throw "Error: kubeseal is not installed or not in PATH."
}

if (-not (Test-Path $InputSecret)) {
    throw "Error: input secret file not found: $InputSecret"
}

if (-not $OutputFile) {
    $OutputFile = [System.IO.Path]::ChangeExtension($InputSecret, ".sealed.yaml")
}

if (-not (Test-Path $CertFile)) {
    throw "Error: public certificate not found: $CertFile"
}

kubeseal `
    --format yaml `
    --cert $CertFile `
    -f $InputSecret `
    -w $OutputFile

Write-Host "SealedSecret written to: $OutputFile"