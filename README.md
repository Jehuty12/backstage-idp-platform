# Backstage Internal Developer Platform — Projet CV

Ce dépôt rassemble les artefacts et la documentation pour construire une Internal Developer Platform (IDP) basée sur Backstage, déployée localement sur Minikube avec GitOps (ArgoCD), Helm et GitHub Actions.

Objectif
- Créer une IDP complète, reproductible localement, qui montre :
  - création self-service de services via Backstage
  - pipelines CI (GitHub Actions) build/push
  - déploiement GitOps (ArgoCD + Helm)
  - gestion des secrets et observabilité

Stack technique
- Backstage (portail développeur)
- Kubernetes local via Minikube
- ArgoCD (GitOps)
- Helm (charts)
- GitHub Actions (CI/CD)
- Sealed Secrets (gestion locale des secrets)
- Prometheus / Grafana / Loki (observabilité)

Architecture (expliquée)
- Backstage : catalogue + templates (scaffolder) — point d’entrée développeur.
- GitHub : héberge les repos de services et le repo infrastructure (Helm charts + App-of-Apps).
- GitHub Actions : build, tests, push d’images, et mise à jour des manifests Helm/values.
- ArgoCD : surveille infrastructure et synchronise sur Minikube.
- Sealed Secrets / Vault : stockage sécurisé des secrets.

Flux CI/CD résumé
1. Developer crée un repo/service (via Backstage ou manuellement).
2. Push → GitHub Actions : tests, build image, push vers GHCR.
3. Workflow met à jour infrastructure (image tag dans values.yaml) ou ouvre une PR.
4. ArgoCD détecte changement et déploie dans Minikube.

Prérequis (local)
- Windows (WSL2 recommandé) ou Linux/Mac
- Docker Desktop
- minikube
- kubectl
- helm
- git

Quickstart local — Vagrant + VirtualBox (Mode équipe)

**Configuration préalable (important)** :

Si tu utilises G:\VMs pour centraliser les disques des VMs, créer le répertoire :
```powershell
mkdir G:\VMs\backstage-idp-k8s\disks
```

Puis éditer `Vagrantfile` ligne ~12 :
```ruby
# Décommenter cette ligne pour utiliser G:\VMs
DISK_DIR = "G:\\VMs\\backstage-idp-k8s\\disks"
```

Voir [docs/vagrant/SETUP.md](docs/vagrant/SETUP.md) pour les détails de cette organisation.

**Phase 1 : Setup cluster Kubernetes**

```bash
# Script automatisé (Windows PowerShell)
.\scripts\vagrant-setup.ps1

# Ou manuellement
vagrant up master
vagrant provision master
vagrant up worker1 worker2
vagrant provision worker1 worker2

# Vérifier
vagrant ssh master
sudo kubectl get nodes
```

Voir [docs/vagrant/SETUP.md](docs/vagrant/SETUP.md) pour le dépannage.

**Phase 2 : Installer ArgoCD & outils**

```bash
# SSH au master
vagrant ssh master

# Créer namespace ArgoCD
sudo kubectl create namespace argocd

# Installer ArgoCD
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Vérifier
sudo kubectl get pods -n argocd
```

**Alternative rapide — Minikube (pour tests uniquement)**

```bash
minikube start --driver=docker
kubectl get nodes
```

Structure du projet (suggestion)
- `infrastructure/` — Helm charts, App-of-Apps ArgoCD, values per env
- `services/` — exemples de microservices (ex: `node-hello-service`)
- `backstage/` — configuration Backstage (catalog, templates)
- `docs/` — diagrammes, captures d'écran, playbook de démo

Comment utiliser ce README au fil du projet
- Met à jour la section "Progression" ci-dessous à chaque jalon terminé.
- Copier/coller les commandes utiles dans les sections docs/ au fur et à mesure.
- Ajouter des liens vers les commits, PRs, captures d’écran et la vidéo de démonstration.

Progression / Checklist (à tenir à jour)
- [x] Préparer l'environnement local (Minikube, kubectl, Helm)
- [x] Provisionner cluster Vagrant/VirtualBox (kubeadm) — Kubernetes 1.31.14
- [x] Initialiser master et installer CNI (Calico) — EN COURS
- [ ] Démarrer workers et rejoindre le cluster
- [ ] Installer et configurer ArgoCD dans Kubernetes
- [ ] Installer Sealed Secrets (local dev)
- [ ] Installer Backstage localement et configurer le catalogue
- [x] Créer un repo `infrastructure` avec Helm charts et App-of-Apps ArgoCD
- [x] Scaffold d'un microservice Node.js + Helm chart + Backstage template
- [x] Ajouter templates Helm (Deployment, Service, _helpers)
- [x] Configurer GitHub Actions CI (build/push + update infra)
- [ ] Intégrer ArgoCD pour déploiement GitOps automatique
- [ ] RBAC et accès sécurisé
- [ ] Observabilité: Prometheus/Grafana et logs (Loki/Fluentd)
- [ ] Documentation, demo vidéo et livrables CV

Livrables attendus
- infrastructure/ (repo ou dossier) : Helm charts et manifests ArgoCD
- services/node-hello-service : exemple de service (source, Dockerfile, helm)
- backstage/ : templates Scaffolder et config catalogue
- docs/demo.mp4 : courte démo (5–10 min)

Notes pour l’entretien
- Documente les choix (mono vs multi-repo, choix secrets, stratégie de promotion).
- Capture les problèmes rencontrés et les solutions (tuning Minikube, auth ArgoCD, etc.).

Prochaine étape recommandée
- Scaffolder les repos de base : infrastructure, services/node-hello-service, backstage-config.

Cluster Vagrant / VirtualBox
- Le projet peut être exécuté sur un mini-cluster K8s provisionné via Vagrant/VirtualBox.
- Un `Vagrantfile` fourni crée 3 VM (1 master, 2 workers) et installe Docker + kubeadm.
- Démarrage (exécuter dans l’ordre) :
```bash
vagrant up master
vagrant ssh master  # pour vérifier kubeadm init et installer le CNI
vagrant up worker1 worker2
```

Notes:
- Sur Windows, utiliser WSL2/cmd avec VirtualBox installé. Ajuster mémoire/CPU dans le `Vagrantfile` si nécessaire.
- Les scripts de provisioning initiaux installent les outils K8s et génèrent un script `join.sh` partagé dans le dossier `/vagrant`.


---
_Fichier généré automatiquement par l’assistant. Mets-le à jour au fur et à mesure et utilise les liens vers les fichiers/PRs pour prouver le travail._
Statut déploiement en cours :
- ✓ Master VM running (Kubernetes 1.31.14)
- ⏳ kubeadm init + Calico CNI en cours...
- ⏱️ Prochaines étapes : démarrer workers, installer ArgoCD, tester CI/CD

Commits récents (dev branch) :
```
chore(vagrant): upgrade kubernetes to v1.31 (latest stable)
feat(github-actions): add CI/CD workflows for build, test, and infra updates
```

Pour continuer :
```bash
# Vérifier l'état du cluster une fois kubeadm init terminé
vagrant ssh master
sudo kubectl get nodes
sudo kubectl get pods -A

# Démarrer les workers
vagrant up worker1 worker2
vagrant provision worker1 worker2

# Vérifier le cluster complet
vagrant ssh master
sudo kubectl get nodes
```