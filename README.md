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

Quickstart local (résumé des commandes)
```bash
# Démarrer minikube (driver Docker)

# Option A — Minikube (alternatif)
minikube start --driver=docker

# Option B — Vagrant + VirtualBox (preferred for this project)
# À la racine du projet :
# vagrant up master
# vagrant up worker1 worker2

# Vérifier kubectl
kubectl get nodes

# Installer ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Installer Sealed Secrets (dev)
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml

# Lancer Backstage en local (dans un dossier backstages-app)
# npx @backstage/create-app
# cd app && yarn dev
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
- [ ] Installer et configurer ArgoCD dans Minikube
- [ ] Installer Backstage localement et configurer le catalogue
- [ ] Créer un repo `infrastructure` avec Helm charts et App-of-Apps ArgoCD
- [ ] Scaffold d'un microservice Node.js + Helm chart + Backstage template
- [ ] Configurer GitHub Actions CI (build/push + update infra)
- [ ] Intégrer ArgoCD pour déploiement GitOps automatique
- [ ] Ajouter gestion des secrets (Sealed Secrets / Vault) et RBAC
- [ ] Observabilité: Prometheus/Grafana et logs (Loki/Fluentd)
- [ ] Documentation, demo vidéo et livrables CV (EN COURS)

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
