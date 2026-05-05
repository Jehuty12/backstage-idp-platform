# infrastructure — Helm charts & ArgoCD

Ce dossier contient les Helm charts et les manifests ArgoCD pour déployer les services depuis Git (App-of-Apps pattern).

Arborescence suggérée
- `argocd/` : manifests ArgoCD (App-of-Apps root)
- `charts/` : charts Helm pour les services (ex: node-hello)
- `values/` : valeurs par environnement (dev/staging/prod)

Pour la démo locale, le chart `node-hello` est inclus.
