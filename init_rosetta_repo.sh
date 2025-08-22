#!/usr/bin/env bash
# init_rosetta_repo.sh
# Create the Rosetta Calculus repository scaffold

set -e

TARGET=${1:-rosetta-calculus}

if [ -d "$TARGET" ]; then
  echo "Directory $TARGET already exists. Aborting."
  exit 1
fi

echo "Creating scaffold at $TARGET"
mkdir -p $TARGET
cd $TARGET

# --- top-level files ---
cat > README.md <<'EOF'
# Rosetta Calculus (RC)

Typed atoms & combinators for universal, stable, interpretable feature construction — with OPAL search.
EOF

cat > pyproject.toml <<'EOF'
[project]
name = "rosetta-calculus"
version = "0.1.0"
description = "Rosetta Calculus: typed atoms and combinators with OPAL search"
authors = [ { name = "Your Name", email = "you@example.com" } ]
readme = "README.md"
requires-python = ">=3.9"
dependencies = ["numpy", "scipy"]
EOF

echo "MIT License (replace with full text)" > LICENSE
echo "__pycache__/" > .gitignore
echo "# Contributing" > CONTRIBUTING.md
echo "# Code of Conduct" > CODE_OF_CONDUCT.md
echo "# Security\nContact: you@example.com" > SECURITY.md
echo "title: Rosetta Calculus" > CITATION.cff

# --- core package dirs ---
for m in types atoms combinators rn opal metrics registry; do
  mkdir -p rosetta/$m
  echo "\"\"\"$m module (scaffold)\"\"\"" > rosetta/$m/__init__.py
  echo "# $m\nPlaceholder" > rosetta/$m/README.md
done
echo '"""Rosetta Calculus package."""' > rosetta/__init__.py

# --- registry starter ---
cat > rosetta/registry/REGISTRY.yml <<'EOF'
types:
  path: {kind: Path, shape: T×C, metric: L2, group: [shift]}
atoms:
  - {name: FFT, in: path, out: spectrum, diff: true}
EOF

# --- examples ---
mkdir -p examples
for nb in timeseries_synthetic images_scattering2d graphs_wavelets; do
  cat > examples/$nb.ipynb <<'JSON'
{
 "nbformat":4,
 "nbformat_minor":5,
 "metadata":{},
 "cells":[{"cell_type":"markdown","metadata":{},"source":["# Placeholder notebook"]}]
}
JSON
done

# --- tests ---
mkdir -p tests
echo "def test_placeholder():\n    assert True" > tests/test_placeholder.py

# --- docs ---
mkdir -p docs
echo "# Rosetta Calculus docs" > docs/index.md

# --- scripts ---
mkdir -p scripts
cat > scripts/profile_atom.py <<'EOF'
#!/usr/bin/env python3
print("Profile placeholder atom")
EOF
chmod +x scripts/profile_atom.py

# --- github actions ---
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'EOF'
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with: {python-version: '3.10'}
      - run: pip install pytest || true
      - run: pytest -q || true
EOF

echo "Scaffold complete at $(pwd)"
