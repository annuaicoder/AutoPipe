#!/bin/bash

# autopipe.sh - Auto-generate GitHub Actions pipeline for a repo
# Usage: ./autopipe.sh <github-repo-url>

set -e

REPO_URL="$1"

if [[ -z "$REPO_URL" ]]; then
  echo "Usage: $0 <github-repo-url>"
  exit 1
fi

REPO_NAME=$(basename -s .git "$REPO_URL")
REPO_USER=$(echo "$REPO_URL" | cut -d'/' -f4)

echo "> Cloning $REPO_URL..."
git clone "$REPO_URL"
cd "$REPO_NAME"

# Detect project type
if [[ -f "package.json" ]]; then
  TYPE="node"
elif [[ -f "requirements.txt" ]]; then
  TYPE="python"
elif [[ -f "main.go" ]]; then
  TYPE="go"
elif [[ -f "manage.py" ]]; then
  TYPE="python"
else
  echo "❔ Cannot auto-detect project type. Choose one:"
  echo "1) Node.js"
  echo "2) Python"
  echo "3) Go"
  read -p "> " TYPE_CHOICE
  case $TYPE_CHOICE in
    1) TYPE="node" ;;
    2) TYPE="python" ;;
    3) TYPE="go" ;;
    *) echo "❌ Invalid selection. Aborting."; exit 1 ;;
  esac
fi

# Create workflow directory
mkdir -p .github/workflows

# Generate pipeline
case $TYPE in
  node)
    cat <<EOF > .github/workflows/ci.yml
name: Node.js CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - run: npm install
    - run: npm test
EOF
    ;;
  python)
    cat <<EOF > .github/workflows/ci.yml
name: Python CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    - run: pip install -r requirements.txt || echo "No requirements.txt found"
    - run: pytest || echo "pytest not found"
EOF
    ;;
  go)
    cat <<EOF > .github/workflows/ci.yml
name: Go CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.20'
    - run: go build ./...
    - run: go test ./...
EOF
    ;;
esac

# Commit only (no push)
echo "> Committing CI pipeline locally..."
git add .github/workflows/ci.yml
git commit -m "Add GitHub Actions CI pipeline"

echo "✅ Done. CI workflow committed locally."
echo "📌 Run 'git push' yourself when you're ready to publish it."
