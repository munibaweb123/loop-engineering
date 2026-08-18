#!/usr/bin/env python3
"""Checker for the daily digest draft.

Verifies that the draft posted to the tracking issue accurately reflects
the actual repo state. Used by the reviewer agent and by humans.

Usage: python3 check.py [path-to-repo]
"""
import subprocess
import sys
from pathlib import Path
from datetime import datetime, timedelta


def run(cmd, cwd=None):
    """Run a command and return stdout."""
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, cwd=cwd
    )
    return result.stdout.strip(), result.returncode


def check_commits(repo_path):
    """Check commits from the last 24 hours."""
    print("=== Checking commits ===")
    stdout, rc = run(
        'git log --since="1 day ago" --oneline --no-merges', cwd=repo_path
    )
    if rc != 0:
        print("ERROR: git log failed")
        return False

    lines = [l for l in stdout.split('\n') if l.strip()]
    print(f"Found {len(lines)} commits in the last 24 hours:")
    for line in lines[:5]:  # Show first 5
        print(f"  {line}")
    if len(lines) > 5:
        print(f"  ... and {len(lines) - 5} more")
    return True


def check_issues(repo_path):
    """Check open issues."""
    print("\n=== Checking issues ===")
    stdout, rc = run("gh issue list --state open --limit 10", cwd=repo_path)
    if rc != 0:
        print("ERROR: gh issue list failed (is gh installed and authenticated?)")
        return False

    lines = [l for l in stdout.split('\n') if l.strip()]
    print(f"Found {len(lines)} open issues:")
    for line in lines[:5]:
        print(f"  {line}")
    if len(lines) > 5:
        print(f"  ... and {len(lines) - 5} more")
    return True


def check_prs(repo_path):
    """Check open PRs."""
    print("\n=== Checking PRs ===")
    stdout, rc = run("gh pr list --state open --limit 10", cwd=repo_path)
    if rc != 0:
        print("ERROR: gh pr list failed (is gh installed and authenticated?)")
        return False

    lines = [l for l in stdout.split('\n') if l.strip()]
    print(f"Found {len(lines)} open PRs:")
    for line in lines[:5]:
        print(f"  {line}")
    if len(lines) > 5:
        print(f"  ... and {len(lines) - 5} more")
    return True


def check_restricted_files(repo_path):
    """Check that no restricted files were modified."""
    print("\n=== Checking restricted files ===")
    stdout, rc = run("git diff --name-only HEAD~1..HEAD", cwd=repo_path)
    if rc != 0:
        print("No recent commits to check")
        return True

    restricted = ['CLAUDE.md', 'AGENTS.md', '.claude/']
    modified = [f for f in stdout.split('\n') if f.strip()]
    violations = []

    for file in modified:
        for r in restricted:
            if file.startswith(r) or file == r:
                violations.append(file)

    if violations:
        print(f"ERROR: Restricted files were modified: {violations}")
        return False

    print("No restricted files modified")
    return True


def main():
    repo_path = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()

    print(f"Checking repo: {repo_path}")
    print(f"Time: {datetime.now().isoformat()}")
    print()

    results = {
        "commits": check_commits(repo_path),
        "issues": check_issues(repo_path),
        "prs": check_prs(repo_path),
        "restricted": check_restricted_files(repo_path),
    }

    print("\n=== Summary ===")
    for check, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {check}: {status}")

    all_passed = all(results.values())
    print(f"\nOverall: {'✅ ALL CHECKS PASSED' if all_passed else '❌ SOME CHECKS FAILED'}")

    return 0 if all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
