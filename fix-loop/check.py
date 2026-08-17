#!/usr/bin/env python3
"""The real checker for fix-loop/buggy-app.

Mechanical, not an opinion: runs the test suite in the target directory and
reports pass/fail counts. Exits 0 only if every test passes. Both the
implementer and the reviewer run this — the reviewer runs it fresh, itself,
rather than trusting a report about it.

Usage: python3 check.py [path-to-buggy-app]   (defaults to ./buggy-app)
"""
import subprocess
import sys
from pathlib import Path


def main():
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "buggy-app").resolve()
    test_file = target / "test_intervals.py"
    if not test_file.exists():
        print(f"no {test_file} -- nothing to check")
        return 1

    result = subprocess.run(
        [sys.executable, "-m", "unittest", "test_intervals", "-v"],
        cwd=target,
        capture_output=True,
        text=True,
    )

    # unittest -v writes its report (including the traceback of any failure) to stderr.
    print(result.stdout, end="")
    print(result.stderr, end="")

    ok = result.returncode == 0
    print("PASS -- all tests green" if ok else "FAIL -- see above")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
