#!/usr/bin/env python3
"""Routine B — The Executor (Webhook Receiver)

Listens for POST requests and runs the approval action.
Trigger: curl to http://localhost:8080/approve
Auth: Bearer token from .env

Usage:
    export APPROVAL_TOKEN=your-secret-token
    python routine-b-server.py

Then fire with:
    curl -X POST http://localhost:8080/approve \
      -H "Authorization: Bearer $APPROVAL_TOKEN" \
      -H "Content-Type: application/json"
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler


def load_dotenv():
    """Load .env file from the same directory as this script."""
    env_path = Path(__file__).parent / ".env"
    if not env_path.exists():
        return {}
    env = {}
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    return env


# Load config from .env file
_env = load_dotenv()
TOKEN = _env.get("APPROVAL_TOKEN")
if not TOKEN:
    print("ERROR: APPROVAL_TOKEN not found in .env")
    print("  Create .env with: echo 'APPROVAL_TOKEN=your-token' > .env")
    sys.exit(1)

TRACKING_ISSUE = _env.get("TRACKING_ISSUE", "1")


class ApprovalHandler(BaseHTTPRequestHandler):
    """Handles the /approve endpoint."""

    def do_POST(self):
        if self.path != "/approve":
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found")
            return

        # Check bearer token
        auth = self.headers.get("Authorization", "")
        if auth != f"Bearer {TOKEN}":
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"Unauthorized")
            print(f"[{datetime.now()}] Unauthorized attempt")
            return

        # Read request body
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b"{}"

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            data = {}

        print(f"[{datetime.now()}] Approval request received")
        print(f"  Text: {data.get('text', '(none)')}")

        # Run the approval action via opencode
        try:
            result = subprocess.run(
                [
                    "opencode", "run",
                    f"Read the latest comment on issue #{TRACKING_ISSUE}. "
                    "Post a reply: '✅ Approved by human gate'. "
                    "If any PRs are mentioned, add the 'approved' label to them."
                ],
                capture_output=True,
                text=True,
                timeout=120
            )

            if result.returncode == 0:
                print(f"  Result: {result.stdout[:200]}")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "approved",
                    "timestamp": datetime.now().isoformat()
                }).encode())
            else:
                print(f"  Error: {result.stderr[:200]}")
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "error",
                    "message": result.stderr[:200]
                }).encode())

        except subprocess.TimeoutExpired:
            print("  Error: opencode run timed out")
            self.send_response(504)
            self.end_headers()
            self.wfile.write(b"Timeout")
        except FileNotFoundError:
            print("  Error: opencode not found. Is it installed?")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"opencode not found")

    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


def main():
    port = int(_env.get("PORT", "8080"))
    server = HTTPServer(("localhost", port), ApprovalHandler)

    print(f"Routine B server running on http://localhost:{port}")
    print(f"Tracking issue: #{TRACKING_ISSUE}")
    print(f"Token: {TOKEN[:4]}...{TOKEN[-4:]}")
    print()
    print("Fire with:")
    print(f'  curl -X POST http://localhost:{port}/approve \\')
    print(f'    -H "Authorization: Bearer $APPROVAL_TOKEN" \\')
    print(f'    -H "Content-Type: application/json"')
    print()
    print("Press Ctrl+C to stop")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
