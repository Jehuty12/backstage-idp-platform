# Vagrant / VirtualBox — Cluster local

Ce document décrit comment démarrer un petit cluster Kubernetes local avec Vagrant et VirtualBox.

Prérequis
- VirtualBox installé
- Vagrant installé
- Au moins 8GB de RAM libre et 2 CPU par VM idéalement (ou ajuster dans `Vagrantfile`).

Démarrage
1. Démarrer le master :
```bash
vagrant up master
```
2. Vérifier l'état du master :
```bash
vagrant ssh master
sudo kubectl get nodes
sudo kubectl get pods -A
exit
```
3. Démarrer les workers :
```bash
vagrant up worker1 worker2
```

Notes utiles
- Le script de provisioning écrit `/vagrant/join.sh` sur le master une fois `kubeadm init` terminé. Les workers attendent ce fichier et l’exécutent pour rejoindre le cluster.
- Si un worker ne rejoint pas, `vagrant ssh master` puis `sudo cat /vagrant/join.sh` pour obtenir la commande manuelle et la lancer sur le worker.
- Pour recréer les VMs depuis zéro :
```bash
vagrant destroy -f
vagrant up master
vagrant up worker1 worker2
```

Dépannage rapide
- Vérifier que VirtualBox peut démarrer les VMs (interfaces réseau, NAT)
- Ajuster `MEMORY` et `CPUS` dans le `Vagrantfile` si la machine hôte manque de ressources
- Sur Windows, exécuter les commandes depuis WSL2 ou PowerShell avec droits administrateur si besoin
