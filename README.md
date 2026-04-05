# GitHub Actions Self-Hosted Runner (Dockerized)

Dockerized GitHub Actions self-hosted runner with **ephemeral mode** and **security hardening**.

Each job runs in a fresh container — no state leaks between jobs.

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/iamhoonse-dev/github-actions-runner-docker.git
cd github-actions-runner-docker

# 2. Create .env from template
cp .env.example .env
# Edit .env with your GitHub PAT and repository

# 3. Build and run
docker compose up -d --build

# 4. Check logs
docker compose logs -f
```

## Configuration

| Variable | Required | Default | Description |
|---|---|---|---|
| `GITHUB_PAT` | Yes | - | GitHub Personal Access Token (`repo` scope) |
| `GITHUB_REPOSITORY` | Yes | - | Target repository (`owner/repo`) |
| `RUNNER_NAME` | No | `docker-runner` | Runner display name |
| `RUNNER_LABELS` | No | `self-hosted,linux,docker` | Comma-separated labels |

## How It Works

```
Container starts
  → Fetches registration token via GitHub API
  → Configures runner with --ephemeral
  → Processes one job
  → Container exits
  → docker compose restart: always → new container starts
  → (repeat)
```

## Security Features

- **Ephemeral mode**: Fresh environment for every job
- **Container isolation**: No access to host filesystem
- **Resource limits**: CPU (2 cores) and memory (4GB) caps
- **No Docker socket**: Disabled by default (enable in `docker-compose.yml` if needed)
- **no-new-privileges**: Blocks privilege escalation inside container
- **Metadata endpoint blocked**: Prevents cloud IAM token theft

## Docker-in-Docker Support

If your workflows need Docker commands, uncomment the volume mount in `docker-compose.yml`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

> **Warning**: Mounting the Docker socket gives the container full control over the host's Docker daemon. Only enable this for private repositories.

## Updating Runner Version

Edit the `RUNNER_VERSION` arg in `docker/Dockerfile`:

```dockerfile
ARG RUNNER_VERSION=2.333.1
```

Then rebuild:

```bash
docker compose up -d --build
```

## Requirements

- Docker and Docker Compose
- GitHub Personal Access Token with `repo` scope (classic) or `Administration` read/write (fine-grained)