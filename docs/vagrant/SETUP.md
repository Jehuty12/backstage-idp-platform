# Vagrant Setup — Phase 1

Cette phase configure et teste le cluster Kubernetes local via Vagrant + VirtualBox.

## Organisation des fichiers — Disques VM

Par défaut, les fichiers disques des VMs sont stockés dans :
```
backstage-idp-platform/disks/
  ├── disk-master.vdi
  ├── disk-worker1.vdi
  └── disk-worker2.vdi
```

Pour utiliser un emplacement externe (ex: G:\VMs), éditer le `Vagrantfile` :
```ruby
# Option 1 : Stockage local (défaut)
DISK_DIR = File.join(Dir.pwd, "disks")

# Option 2 : Stockage externe (recommandé)
DISK_DIR = "G:\\VMs\\backstage-idp-k8s\\disks"
```

Puis créer le répertoire s'il n'existe pas :
```powershell
mkdir G:\VMs\backstage-idp-k8s\disks
```

## Prérequis

- **VirtualBox** (>= 6.1) — https://www.virtualbox.org/
- **Vagrant** (>= 2.3) — https://www.vagrantup.com/
- **Au minimum** : 8GB RAM libre, 2 CPU par VM (configurable dans `Vagrantfile`)
- **Espace disque** : ~30GB pour 3 VMs (10GB base OS + 10GB disque additionnel chacun)
- **Windows** : utiliser PowerShell avec droits administrateur, ou WSL2 recommandé

## Commandes rapides

### Avec le script automatisé (Linux/Mac/WSL2)
```bash
bash scripts/vagrant-setup.sh
```

### Avec le script PowerShell (Windows)
```powershell
cd g:\DevProjects\backstage-idp-platform
.\scripts\vagrant-setup.ps1
```

### Commandes manuelles (étape par étape)
```bash
# Démarrer le master
vagrant up master

# Provisionner le master (install Docker, kubeadm, init cluster)
vagrant provision master

# Vérifier le master
vagrant ssh master
sudo kubectl get nodes
sudo kubectl get pods -A
exit

# Démarrer les workers
vagrant up worker1 worker2

# Provisionner les workers
vagrant provision worker1 worker2

# Vérifier le cluster complet
vagrant ssh master
sudo kubectl get nodes
```

## Que se passe-t-il ?

1. **Vagrant up** crée 3 VMs (master, worker1, worker2) sur VirtualBox
2. **Provisioning (install.sh)** installe sur chaque VM :
   - Debian Bookworm (base box)
   - Docker (runtime)
   - kubeadm, kubelet, kubectl
   - Swap désactivé (requis par K8s)
3. **Master init** :
   - `kubeadm init` crée le control plane
   - Installe Calico (CNI) pour la connectivité réseau
   - Génère `/vagrant/join.sh` pour les workers
4. **Worker join** :
   - Attendent le `join.sh` du master
   - Rejoignent le cluster

## Dépannage rapide

### Les VMs ne démarrent pas
```bash
# Vérifier VirtualBox
VBoxManage list vms

# Vérifier les erreurs Vagrant
vagrant status
vagrant up master --debug
```

### Le master n'initialise pas kubeadm
```bash
vagrant ssh master
sudo journalctl -u kubelet -n 50
sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=192.168.0.0/16
```

### Les workers ne rejoignent pas
```bash
# Vérifier le join script
cat /vagrant/join.sh

# Rejoindre manuellement
vagrant ssh worker1
sudo bash /vagrant/join.sh
```

### Récréer depuis zéro
```bash
vagrant destroy -f
vagrant up master
vagrant provision master
vagrant up worker1 worker2
vagrant provision worker1 worker2
```

## Une fois le cluster prêt

### Accéder à kubeconfig
```bash
vagrant ssh master
sudo cat /home/vagrant/.kube/config

# Copier localement si nécessaire
scp vagrant@192.168.56.10:/home/vagrant/.kube/config ~/.kube/config-vagrant
```

### Ports et accès
- Master SSH: `vagrant ssh master` (ou SSH direct: `ssh vagrant@192.168.56.10`)
- Kubernetes API: `https://192.168.56.10:6443` (depuis worker SSH, ou port-forward)
- Worker1 port 30114 → 80 (forwarded pour ingress, config en Vagrantfile)

### Nettoyage des VMs

```bash
# Arrêter les VMs (les garder)
vagrant halt

# Détruire les VMs
vagrant destroy -f

# Supprimer aussi les disques (optionnel)
rm -r disks/   # ou rm -r G:\VMs\backstage-idp-k8s\disks\
```

## Organisation recommandée — Structure multi-projets

## Organisation recommandée — Structure multi-projets

Si tu utilises G:\VMs pour héberger les disques de plusieurs clusters/projets :

```
G:\VMs\
├── backstage-idp-k8s\
│   ├── disks\
│   │   ├── disk-master.vdi
│   │   ├── disk-worker1.vdi
│   │   └── disk-worker2.vdi
│   └── Vagrantfile (symlink ou copie)
├── other-project-k8s\
│   ├── disks\
│   └── Vagrantfile
└── README.md (doc centralisée)
```

**Avantages** :
- Sépare le code du projet (`G:\DevProjects\backstage-idp-platform`) des gros fichiers disques
- Facile à agrandir ou migrer les disques
- Peut être sur un disque physique différent (optimisation I/O)

**Configuration** :
1. Créer `G:\VMs\backstage-idp-k8s\disks\`
2. Éditer `Vagrantfile` ligne 12 :
```ruby
DISK_DIR = "G:\\VMs\\backstage-idp-k8s\\disks"
```
3. Lancer les VMs depuis `G:\DevProjects\backstage-idp-platform` : les disques iront automatiquement dans G:\VMs

## Prochaine étape

Une fois le cluster stable, passer à **Phase 2 : ArgoCD Setup**
- Créer un namespace `argocd`
- Installer ArgoCD via manifests
- Configurer l'accès UI + CLI

Voir `docs/argocd/README.md` (à créer).
