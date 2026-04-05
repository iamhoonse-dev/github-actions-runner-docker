#!/bin/bash
set -euo pipefail

RUNNER_WORKDIR="/home/runner/actions-runner"

# Validate required environment variables
if [ -z "${GITHUB_PAT:-}" ]; then
    echo "Error: GITHUB_PAT is required"
    exit 1
fi

if [ -z "${GITHUB_REPOSITORY:-}" ]; then
    echo "Error: GITHUB_REPOSITORY is required (format: owner/repo)"
    exit 1
fi

RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,docker}"
RUNNER_GROUP="${RUNNER_GROUP:-Default}"

# Get registration token from GitHub API
echo "Requesting registration token for ${GITHUB_REPOSITORY}..."
REG_TOKEN=$(curl -fsSL \
    -X POST \
    -H "Authorization: token ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" \
    | jq -r '.token')

if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" = "null" ]; then
    echo "Error: Failed to get registration token. Check your GITHUB_PAT and GITHUB_REPOSITORY."
    exit 1
fi

# Cleanup function: remove runner on exit
cleanup() {
    echo "Removing runner..."
    cd "$RUNNER_WORKDIR"
    ./config.sh remove --token "$REG_TOKEN" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Configure the runner in ephemeral mode
cd "$RUNNER_WORKDIR"
./config.sh \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "$REG_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --runnergroup "$RUNNER_GROUP" \
    --work "_work" \
    --ephemeral \
    --unattended \
    --replace \
    --disableupdate

echo "Runner configured. Starting..."

# Run the runner (ephemeral: exits after one job)
./run.sh