# Backstage Internal Developer Platform — Projet CV

Ce dépôt rassemble les artefacts et la documentation pour construire une Internal Developer Platform (IDP) basée sur Backstage, déployée localement sur Kubernetes via Vagrant/VirtualBox avec GitOps (ArgoCD), Helm et GitHub Actions.

## Objectif

Créer une IDP complète et reproductible localement qui montre :
- Création self-service de services via Backstage
- Pipelines CI (GitHub Actions) pour build/push d'images
- Déploiement GitOps automatique (ArgoCD + Helm)
- Gestion sécurisée des secrets (Sealed Secrets)
- RBAC et contrôle d'accès (ArgoCD)

## Stack technique

- **Kubernetes** : kubeadm 1.31.14 sur Vagrant/VirtualBox
- **CNI** : Calico 3.27.3
- **ArgoCD** : GitOps synchronization
- **Helm** : Package manager Kubernetes
- **Backstage** : Portail développeur + Scaffolder
- **Sealed Secrets** : Gestion locale des secrets chiffrés
- **GitHub Actions** : CI/CD pipelines

## Architecture

```
Developer → Backstage → GitHub (service repo)
                ↓
          GitHub Actions (build/test)
                ↓
          GHCR (push image)
                ↓
          GitHub (infra repo avec values.yaml)
                ↓
          ArgoCD (sync Kubernetes)
                ↓
          Kubernetes cluster (Vagrant VMs)
```

## Prérequis (local)

- Windows ou Linux/Mac
- VirtualBox (installé et fonctionnel)
- Vagrant (installé et fonctionnel)
- git (pour cloner et versionner)

## Quickstart — Cluster Vagrant/VirtualBox

### Configuration préalable

Si tu utilises G:\VMs pour centraliser les disques des VMs, créer le répertoire :
```powershell
mkdir G:\VMs\backstage-idp-k8s\disks
```

Puis éditer `Vagrantfile` ligne ~12 :
```ruby
# Décommenter cette ligne pour utiliser G:\VMs
DISK_DIR = "G:\\VMs\\backstage-idp-k8s\\disks"
```

Voir [docs/vagrant/SETUP.md](docs/vagrant/SETUP.md) pour les détails.

### Phase 1 : Setup cluster Kubernetes

```bash
# Manuellement
vagrant up master
vagrant up worker1 worker2

# Vérifier l'état
vagrant ssh master
sudo kubectl get nodes
sudo kubectl get pods -A
```

Les scripts de provisioning automatiques :
- Installent docker/containerd, kubeadm, kubelet, kubectl
- Exécutent `kubeadm init` sur master
- Déploient Calico CNI
- Génèrent `kubeadm-join-command.sh` pour les workers
- Rejoignent automatiquement les workers au cluster

Voir [docs/vagrant/SETUP.md](docs/vagrant/SETUP.md) pour le dépannage.

### Phase 2 : Accéder à ArgoCD

Une fois le cluster opérationnel (3 nœuds Ready), ArgoCD est automatiquement installé.

```bash
# Accéder à ArgoCD depuis la machine hôte
# URL: https://192.168.56.10:31200
# Accepter le certificat auto-signé
# Utilisateurs disponibles: admin, superviseur, dev, bob
```

## Structure du projet

```
backstage-idp-platform/
├── infrastructure/
│   ├── argocd/
│   │   ├── app-of-apps.yaml
│   │   ├── users-rbac.yaml
│   │   └── apps/
│   │       └── node-hello.yaml
│   ├── charts/
│   │   └── node-hello/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   └── README.md
├── services/
│   └── node-hello-service/
│       ├── src/
│       ├── Dockerfile
│       ├── package.json
│       ├── helm/
│       └── README.md
├── scripts/
│   ├── install.sh
│   ├── install-worker.sh
│   ├── argocd-setup.sh
│   ├── setup-argocd-users.sh
│   ├── setup-argocd-users.py
│   └── expose-argocd.sh
├── docs/
│   ├── vagrant/
│   └── github-actions/
├── Vagrantfile
├── .gitignore
└── README.md
```

## Progression / Checklist

- [x] Préparer l'environnement local (Vagrant, VirtualBox)
- [x] Provisionner cluster Vagrant/VirtualBox (kubeadm) — Kubernetes 1.31.14
- [x] Initialiser master et installer CNI (Calico)
- [x] Démarrer workers et rejoindre le cluster
- [x] Installer et configurer ArgoCD
- [x] Exposer ArgoCD via NodePort (https://192.168.56.10:31200)
- [x] Créer utilisateurs et RBAC dans ArgoCD (admin, superviseur, dev, bob)
- [x] Créer infrastructure avec Helm charts et App-of-Apps
- [x] Scaffold microservice Node.js + Helm + Backstage template
- [x] Configurer GitHub Actions CI (build/push)
- [x] Installer Sealed Secrets et valider le chiffrement/déchiffrement de test
- [ ] Installer et configurer Backstage
- [ ] Intégrer ArgoCD avec déploiement GitOps complet
- [ ] Observabilité (Prometheus/Grafana/Loki)
- [ ] Documentation complète + démo vidéo

## Statut Cluster (05/06/2026)

### ✓ Cluster Kubernetes — Operationnel

| Composant | Statut |
|-----------|--------|
| Master VM | ✓ Running (K8s 1.31.14, Calico 3.27.3) |
| Worker 1 | ✓ Ready |
| Worker 2 | ✓ Ready |
| ArgoCD | ✓ Running (NodePort 31200) |

### ✓ Utilisateurs ArgoCD

| Utilisateur | Rôle | Permissions |
|-------------|------|-------------|
| admin | admin | Accès complet |
| superviseur | superviseur | Apps, repos, clusters, projets |
| dev | app-deployer | Sync/update apps |
| bob | read-only | Lecture seule |

### Accès ArgoCD

- **URL** : https://192.168.56.10:31200
- **Accepter** le certificat auto-signé
- **Identifiants** :
  ```
  admin: AdminPass123!
  superviseur: SuperPass456!
  dev: DevPass789!
  bob: BobReadOnly!@
  ```

## Gestion du cluster

```bash
# Arrêter proprement
vagrant halt

# Redémarrer
vagrant up

# Accéder au master
vagrant ssh master

# Vérifier l'état
kubectl get nodes
kubectl get pods -A

# Voir les logs ArgoCD
kubectl -n argocd logs -f deployment/argocd-server
```

## Commits récents (dev branch)

```
docs: update README with current cluster status and user credentials
feat: add ArgoCD users, RBAC configuration and user setup scripts
chore: merge cleanup-ignore into dev
```

## Prochaines étapes

1. **Backstage** : Installer localement, configurer catalogue + templates Scaffolder
2. **App-of-Apps** : Déployer manifests ArgoCD pour services d'exemple
3. **Observabilité** : Prometheus, Grafana, Loki

## Option A - Workflow Sealed Secrets

- Un helper réutilisable est disponible dans `scripts/seal-secret.sh` et `scripts/seal-secret.ps1`
- Utiliser ce workflow ensuite pour sécuriser les secrets de Backstage
- Garder les valeurs sensibles hors du repo tout en restant compatible GitOps

Usage typique:

```bash
./scripts/seal-secret.sh /chemin/secret.yaml /chemin/secret-sealed.yaml ~/sealing-key.pub
```

### Secrets Backstage à préparer

Avant l'installation complète de Backstage, préparer au minimum ces secrets:

- `backstage-github-token` ou une GitHub App pour publier les repositories générés par le Scaffolder
- `backstage-session-secret` pour la session utilisateur
- `backstage-auth` si OAuth GitHub/GitLab est activé plus tard
- `backstage-postgres` si Backstage utilise une base PostgreSQL dédiée

Ces valeurs devront être transformées en `SealedSecret` avant d'être ajoutées au flux GitOps.

## Notes de développement

- Tous les secrets sensibles doivent être chiffrés avec Sealed Secrets avant commit
- Utiliser des conventional commits pour versioning
- Branches : `main` (prod), `dev` (pre-prod), `feature/*` (développement)
- Documentation : mise à jour à chaque jalon terminé

---

**Créé le** : 05/06/2026  
**Statut** : En cours de développement  
**Environnement** : Local (Vagrant/VirtualBox 3-node cluster)
