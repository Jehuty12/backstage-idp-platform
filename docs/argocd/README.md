# ArgoCD Setup & GitOps

Ce document explique comment déployer et configurer ArgoCD pour la gestion GitOps du cluster.

## Prérequis

- Cluster Kubernetes fonctionnel (Vagrant ou Minikube)
- `kubectl` configuré
- `helm` (optionnel, pour helm charts)

## Installation rapide

### Option 1 — Script automatisé (Linux/Mac/WSL2)
```bash
bash scripts/argocd-setup.sh
```

### Option 2 — Script PowerShell (Windows)
```powershell
.\scripts\argocd-setup.ps1
```

### Option 3 — Manuel
```bash
# Créer le namespace
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Vérifier
kubectl get pods -n argocd
```

## Accéder à ArgoCD UI

### Port-forward local
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Puis https://localhost:8080
```

### Récupérer le password admin
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# Copier le password
```

## Configurer le CLI argocd

```bash
# Installation du CLI (si besoin)
# https://argo-cd.readthedocs.io/en/stable/cli_installation/

# Login
argocd login localhost:8080 --username admin --password <PASSWORD>

# Verifier
argocd cluster list
argocd repo list
```

## Structure des Applications

Applications sont définies en YAML dans `infrastructure/argocd/apps/`.

### Exemple : node-hello Application

Fichier : `infrastructure/argocd/apps/node-hello.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: node-hello
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/your-org/infrastructure'
    targetRevision: main
    path: infrastructure/charts/node-hello
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Champs clés :
- `source.repoURL` : repo Git contenant les manifests (Helm charts, Kustomize, etc.)
- `source.path` : chemin dans le repo
- `destination.server` : API K8s cible
- `syncPolicy.automated` : sync auto quand le Git change
- `syncPolicy.syncOptions` : options de sync (CreateNamespace, etc.)

## App-of-Apps Pattern

L'App-of-Apps est une Application ArgoCD qui gère d'autres Applications.

Fichier racine : `infrastructure/argocd/app-of-apps.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: idp-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/your-org/infrastructure'
    targetRevision: HEAD
    path: argocd/apps
  destination:
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Appliquer l'App-of-Apps :
```bash
kubectl apply -f infrastructure/argocd/app-of-apps.yaml
```

ArgoCD détectera alors les Applications dans le dossier `argocd/apps/` et les synchronisera automatiquement.

## Workflow GitOps

1. **Développeur** pousse du code → Git repo
2. **GitHub Actions** build image, met à jour `infrastructure/charts/node-hello/values.yaml` (image tag)
3. **ArgoCD** détecte le changement Git, compile le Helm chart, et applique les manifests
4. **Cluster** déploie la nouvelle version

## Dépannage

### ArgoCD pod crashe
```bash
kubectl logs -n argocd deployment/argocd-server
```

### Sync ne fonctionne pas
```bash
# Vérifier les credentials Git
argocd repo list

# Refetch le repo
argocd repo refresh https://github.com/your-org/infrastructure

# Forcer la sync
argocd app sync node-hello
```

### Accès à partir du Vagrant master
```bash
vagrant ssh master
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0
# Depuis ton machine : https://192.168.56.10:8080
```

## Secrets avec ArgoCD

Pour les variables sensibles, utiliser Sealed Secrets (voir doc Sealed Secrets).

ArgoCD peut afficher les secrets dans les Applications, mais il faut configurer la déchiffrement côté ArgoCD.

## Prochaines étapes

1. Pousser le repo `infrastructure` sur GitHub
2. Ajouter le repo dans ArgoCD
3. Appliquer l'App-of-Apps
4. Voir les Applications se déployer automatiquement

Voir `docs/github-actions/README.md` pour intégrer le CI/CD côté GitHub.
