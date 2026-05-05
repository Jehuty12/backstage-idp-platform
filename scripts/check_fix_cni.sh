#!/usr/bin/env bash
set -euo pipefail

echo "--- /opt/cni/bin ---"
ls -la /opt/cni/bin || echo "(no /opt/cni/bin)"

echo "--- /usr/lib/cni ---"
ls -la /usr/lib/cni || echo "(no /usr/lib/cni)"

# Create /usr/lib/cni and symlink plugins from /opt/cni/bin if present
sudo mkdir -p /usr/lib/cni
if [ -d /opt/cni/bin ]; then
  for f in /opt/cni/bin/*; do
    if [ -f "$f" ]; then
      sudo ln -sf "$f" /usr/lib/cni/ || true
    fi
  done
fi

echo "--- after ---"
ls -la /usr/lib/cni || true

# Print container runtime info
if command -v containerd >/dev/null 2>&1; then
  echo "containerd status:"
  sudo systemctl is-active containerd || true
  sudo containerd --version || true
fi

if command -v docker >/dev/null 2>&1; then
  echo "docker status:"
  sudo systemctl is-active docker || true
  sudo docker --version || true
fi

exit 0
