# vagrant-setup.ps1
# PowerShell script to setup and test the 3-node Kubernetes cluster with Vagrant/VirtualBox on Windows

Write-Host "=========================================="
Write-Host "Vagrant Kubernetes Cluster Setup (Windows)"
Write-Host "=========================================="

# Check prerequisites
Write-Host ""
Write-Host "[1/5] Checking prerequisites..."
try {
    $vagrantVersion = vagrant --version
    Write-Host "✓ Vagrant found: $vagrantVersion"
} catch {
    Write-Host "❌ Vagrant not installed. Please install from https://www.vagrantup.com/"
    exit 1
}

try {
    # Just check if VirtualBox is installed (no easy way to check on Windows)
    $vboxCheck = Get-Command VirtualBox -ErrorAction Stop
    Write-Host "✓ VirtualBox found"
} catch {
    Write-Host "⚠ VirtualBox may not be in PATH. Make sure it's installed from https://www.virtualbox.org/"
}

# Navigate to project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

# Start master node
Write-Host ""
Write-Host "[2/5] Starting master node (this may take 2-5 minutes)..."
vagrant up master --no-provision 2>&1 | Out-Null
Write-Host "✓ Master node started"

Write-Host ""
Write-Host "[3/5] Provisioning master (installing Docker, kubeadm, etc.)..."
vagrant provision master 2>&1 | Out-Null
Write-Host "✓ Master provisioned"

Write-Host ""
Write-Host "  Waiting 30 seconds for master to initialize kubeadm..."
Start-Sleep -Seconds 30

# Start worker nodes
Write-Host ""
Write-Host "[4/5] Starting worker nodes..."
vagrant up worker1 worker2 --no-provision 2>&1 | Out-Null
Write-Host "✓ Workers started"

Write-Host ""
Write-Host "  Provisioning workers..."
vagrant provision worker1 worker2 2>&1 | Out-Null
Write-Host "✓ Workers provisioned"

# Verify cluster
Write-Host ""
Write-Host "[5/5] Verifying cluster..."
Write-Host ""
Write-Host "Cluster nodes:"
vagrant ssh master -c "sudo kubectl get nodes" 2>&1
Write-Host ""
Write-Host "Cluster pods (all namespaces):"
vagrant ssh master -c "sudo kubectl get pods -A" 2>&1

Write-Host ""
Write-Host "=========================================="
Write-Host "✓ Vagrant cluster setup complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. SSH to master: vagrant ssh master"
Write-Host "  2. Check kubeconfig: sudo cat /home/vagrant/.kube/config"
Write-Host "  3. Deploy ArgoCD next"
