#!/bin/bash
# Setup script for the two-routine gate project
# Installs dependencies and configures the environment

set -euo pipefail

echo "=== Two-Routine Gate Setup ==="
echo

# Check for required tools
echo "Checking required tools..."

check_tool() {
    if command -v "$1" &>/dev/null; then
        echo "  ✅ $1"
        return 0
    else
        echo "  ❌ $1 — $2"
        return 1
    fi
}

MISSING=0
check_tool "git" "required for version control" || MISSING=1
check_tool "gh" "GitHub CLI — install from https://cli.github.com/" || MISSING=1
check_tool "opencode" "OpenCode — install from https://opencode.ai" || MISSING=1
check_tool "python3" "Python 3 — install from https://python.org" || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo
    echo "Install missing tools and run this script again."
    exit 1
fi

echo
echo "All tools available."
echo

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "# Routine B authentication token" > .env
    echo "# Generate a random token: openssl rand -hex 32" >> .env
    echo "APPROVAL_TOKEN=" >> .env
    echo "TRACKING_ISSUE=1" >> .env
    echo
    echo "⚠️  Edit .env and set APPROVAL_TOKEN to a random value:"
    echo "   openssl rand -hex 32"
    echo
else
    echo ".env already exists."
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x routine-a.sh
chmod +x check.py

echo
echo "✅ Setup complete."
echo
echo "Next steps:"
echo "  1. Edit .env and set APPROVAL_TOKEN"
echo "  2. Start Routine B: python routine-b-server.py"
echo "  3. Fire Routine A: bash routine-a.sh"
echo "  4. Review the draft on the tracking issue"
echo "  5. If approved: curl -X POST http://localhost:8080/approve -H 'Authorization: Bearer \$APPROVAL_TOKEN'"
echo
