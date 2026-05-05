# Vagrantfile — Provision a 3-node Kubernetes cluster (kubeadm) on VirtualBox
# Adjust BOX_NAME, MEMORY, CPUS, and IPs as needed.

BOX_NAME           = "debian/bookworm64"
MEMORY             = 2048
CPUS               = 2
# DISK_SIZE and advanced disk setup skipped (requires plugin)

nodes = [
  { name: "master",  ip: "192.168.56.10", role: "master" },
  { name: "worker1", ip: "192.168.56.11", role: "worker" },
  { name: "worker2", ip: "192.168.56.12", role: "worker" }
]

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME
  config.vm.synced_folder ".", "/vagrant", :nfs => false

  nodes.each do |node|
    config.vm.define node[:name] do |node_cfg|
      node_cfg.vm.hostname = node[:name]
      node_cfg.vm.network :private_network, ip: node[:ip]
      node_cfg.vm.provider :virtualbox do |vb|
        vb.name = "k8s-#{node[:name]}"
        vb.memory = MEMORY
        vb.cpus = CPUS
      end

      # Common provisioning: install Docker and Kubernetes tools
      node_cfg.vm.provision "shell", inline: <<-SHELL
        set -eux
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
        # Install Docker
        apt-get install -y docker.io
        systemctl enable --now docker

        # Disable swap
        swapoff -a || true
        sed -i.bak '/ swap / s/^/#/' /etc/fstab || true

        # Kubernetes apt repo
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-get install -y kubelet kubeadm kubectl
        apt-mark hold kubelet kubeadm kubectl
      SHELL

      if node[:role] == "master"
        # Master init: kubeadm init and install a CNI
        node_cfg.vm.provision "shell", inline: <<-SHELL
          set -eux
          # Initialize control plane
          kubeadm init --apiserver-advertise-address=#{node[:ip]} --pod-network-cidr=192.168.0.0/16 || true
          mkdir -p /home/vagrant/.kube
          cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
          chown vagrant:vagrant /home/vagrant/.kube/config

          # Install Calico CNI
          su - vagrant -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"

          # Create a join script for workers
          kubeadm token create --print-join-command > /vagrant/join.sh || true
          chmod +x /vagrant/join.sh || true
        SHELL
      else
        # Worker: wait for join script then run it
        node_cfg.vm.provision "shell", inline: <<-SHELL
          set -eux
          # Wait for join script from master
          for i in {1..60}; do
            if [ -f /vagrant/join.sh ]; then
              break
            fi
            sleep 5
          done
          if [ -f /vagrant/join.sh ]; then
            bash /vagrant/join.sh || true
          else
            echo "join.sh not found after waiting; please run 'vagrant ssh master' and check kubeadm init." >&2
          fi
        SHELL
      end
    end
  end
end
