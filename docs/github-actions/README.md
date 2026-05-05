# GitHub Actions — CI/CD Pipeline

Ce document explique les pipelines CI/CD mise en place avec GitHub Actions.

## Architecture

```
┌─ Developer push code ────────┐
│                              │
├─ test.yml (tests, lint)      │
│                              │
├─ build.yml (build + push)    │
│                              │
├─ Update infra repo           │
│                              │
└─ ArgoCD detects & deploys    │
```

## Pipelines disponibles

### 1. test.yml — Tests & Validation

**Déclenché par :**
- Push sur n'importe quelle branche (si changements dans `services/node-hello-service/`)
- Pull request vers `main` ou `dev`

**Étapes :**
- Setup Node.js 18
- Install dependencies
- Run linter (optionnel)
- Run tests (optionnel)
- Build Docker image (validation)

**Sortie :** ❌ Le build échoue si les tests échouent

### 2. build.yml — Build & Push Docker Image

**Déclenché par :**
- Push sur `main` ou `dev` (si changements dans `services/node-hello-service/`)

**Étapes :**
- Login à GHCR (GitHub Container Registry)
- Build Docker image multi-plateforme
- Push image vers `ghcr.io/your-org/node-hello:TAG`
- Update `infrastructure` repo avec le nouveau tag

**Tags générés :**
```
ghcr.io/your-org/node-hello:dev           # Branche dev
ghcr.io/your-org/node-hello:main-COMMIT   # Branche main avec SHA
ghcr.io/your-org/node-hello:SHA-short     # Short SHA
ghcr.io/your-org/node-hello:latest        # Latest (main seulement)
```

**Sortie :** ArgoCD détecte le changement dans `infrastructure/values.yaml` et déploie

## Configuration requise

### Secrets GitHub

Ajouter dans Settings → Secrets and variables → Actions :

- Aucun secret requis de base (utilise GITHUB_TOKEN)
- Optionnel : `REGISTRY_USERNAME` et `REGISTRY_PASSWORD` pour registres privés

### Permissions GitHub

S'assurer que le workflow a accès à :
- `contents: read` — lecture du code
- `packages: write` — push images GHCR

## Workflow local de développement

### Option 1 — Depuis feature branch

```bash
git checkout dev
git checkout -b feature/my-feature
# Faire les changements
git add .
git commit -m "feat(services): update node-hello"
git push origin feature/my-feature
# Ouvrir PR vers dev
# GitHub Actions lance test.yml
# Une fois validé, fusionner sur dev
```

### Option 2 — Branche dev → main (production)

```bash
# Sur dev, après merge de features
git checkout dev
git pull

# Créer release branch
git checkout -b release/v1.0.0
# Mettre à jour version dans package.json
git commit -m "chore(release): bump to v1.0.0"
git push origin release/v1.0.0

# Ouvrir PR vers main
# test.yml + build.yml lancés
# build.yml pousse image:v1.0.0 et image:latest
# ArgoCD déploie sur prod
```

## Dépannage

### Build échoue sur "Update infrastructure repo"

```
Error: Failed to authenticate with git
```

**Solution :** S'assurer que `GITHUB_TOKEN` a les permissions de push sur le repo `infrastructure`. Voir Settings → Actions → General → Workflow permissions.

### Image ne se push pas à GHCR

```
docker: error response from daemon: unauthorized
```

**Solution :** 
```bash
# Dans le workflow, vérifier le login
- name: Log in to GHCR
  run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login -u ${{ github.actor }} --password-stdin ghcr.io
```

### ArgoCD ne détecte pas les changements

```bash
# Vérifier que ArgoCD a accès au repo
argocd repo list
argocd app sync node-hello
```

## Bonus — Intégration Slack/Email

Ajouter une notification après deploy :

```yaml
- name: Notify Slack
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "🚀 Deployment Status",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Image pushed:* `${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}`\n*Status:* ${{ job.status }}"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Références

- GitHub Actions Docs: https://docs.github.com/en/actions
- Docker Build Push Action: https://github.com/docker/build-push-action
- Metadata Action: https://github.com/docker/metadata-action
