# Rosetta Calculus (RC)

_A typed calculus of atoms & combinators for universal, stable, and interpretable feature construction — with OPAL (Ontology-Programmed Architecture Learning) for typed NAS._

> **TL;DR**  
> Rosetta Calculus (RC) is a small, principled core: **types → atoms → combinators → Rosetta Networks (RN)**.  
> RC models are type-safe by construction, come with stability hooks (Lipschitz/robustness metadata), and plug into **OPAL**, a typed NAS engine that searches only **semantically valid** architectures.

---

## Why Rosetta?

Modern ML glues together powerful operators (wavelets, scattering, signatures, graph kernels, TDA, spectral transforms). RC provides:

- **A typed algebra** that makes such compositions **legal, safe, and reproducible**.
    
- **Stability-aware building blocks** (regularity bounds and invariances travel through the graph).
    
- **Cross-modal transfer** via an ontology of types and adapters.
    
- **OPAL**: a hybrid differentiable + discrete search that explores only type-compatible choices.

---

## Key ideas (one screen)

- **Types**: `(kind, shape, metric, group)` — e.g., `Path(T×C, L2, shift)`, `Spectrum(K×C, L2, phase-shift)`, `FeatureVec(d)`, `Barcode(⋆)`.
    
- **Atoms (operators)**: typed maps `τ_in → τ_out` with metadata: `diff?`, `invariance`, `stability (Lipschitz)`, `cost`.
    
- **Combinators**: `compose`, `concat`, `pool/reduce`, `attention`, `quotient (invariantization)`.
    
- **Adapters**: canonical casts (`Barcode→FeatureVec`, `Spectrum→FeatureVec`, …) that preserve semantics.
    
- **Rosetta Network (RN)**: a typed DAG built from atoms + combinators.
    
- **OPAL**: typed NAS over the RN supergraph — **differentiable relaxation for smooth atoms**, **controller for non-diff atoms**.
    

---

## Installation

```bash
# clone
git clone https://github.com/okuhlemadondo/rosetta-calculus.git
cd rosetta-calculus

# env (choose one)
# Option A: uv
uv venv && source .venv/bin/activate
uv pip install -e ".[dev]"

# Option B: pip
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
pre-commit install
```

---

## Quickstart (10 lines)

```python
from rosetta.types import Path, Spectrum, Feature, Barcode
from rosetta.registry import REGISTRY, Atom, adapter
from rosetta.rn import Node, Compose, Concat, Pool
from rosetta.opal import TypedSearch

# 1) declare types
T_path = Path(shape=("T","C"), metric="L2", group=["shift"])
T_spec = Spectrum(shape=("K","C"), metric="L2", group=["phase-shift"])
T_feat = Feature(dim="d")

# 2) pick atoms (examples shipped in REGISTRY)
FFT    = REGISTRY["FFT"]           # Path -> Spectrum
Scat1D = REGISTRY["Scattering1D"]  # Path -> Feature
Sign2  = REGISTRY["Signature2"]    # Path -> Feature
Spec2V = REGISTRY["SpecPool"]      # Spectrum -> Feature

# 3) build a tiny RN by hand
rn = Concat([Scat1D, Sign2, Compose(Spec2V, FFT)])

# 4) or… let OPAL search a better typed RN under a latency budget
opal = TypedSearch(registry=REGISTRY, budget={"latency_ms": 25})
best = opal.search(input_type=T_path, output_type=T_feat, task="classification", train_data=..., val_data=...)
print(best)  # type-safe, discrete RN
```

---

## The Rosetta Contract (what every atom must declare)

```python
Atom(
  name="Signature2",
  in_type=("Path","T×C","L2",["shift"]),
  out_type=("FeatureVec","d","L2",[]),
  diff=True,
  invariance={"equivariance":"shift"},
  stability={"lipschitz_estimator":"empirical_fd"},
  cost={"flops":"O(T)", "latency":"medium"},
  params={"order":2, "normalization":"zscore"}
)
```

---

## YAML registry (human-editable)

```yaml
types:
  path:     {kind: Path, shape: T×C, metric: L2, group: [shift]}
  spectrum: {kind: Spectrum, shape: K×C, metric: L2, group: [phase-shift]}
  feature:  {kind: FeatureVec, shape: d, metric: L2, group: []}
  barcode:  {kind: Barcode, shape: '*', metric: bottleneck, group: []}

adapters:
  - {name: SpecPool, in: spectrum, out: feature}
  - {name: Barcode2Vec, in: barcode, out: feature}

atoms:
  - {name: FFT, in: path, out: spectrum, diff: true}
  - {name: Scattering1D, in: path, out: feature, diff: true}
  - {name: Signature2, in: path, out: feature, diff: true}
  - {name: PH, in: pointcloud, out: barcode, diff: false}
```

---

## OPAL in 30 seconds

OPAL turns the registry + ontology into a typed supergraph. For each node:

- computes only **type-compatible** atoms (mask invalid ones),
    
- mixes them with **Gumbel-Softmax** during search,
    
- **anneals → prunes → decodes** into a discrete RN, and
    
- optionally inserts **non-differentiable** atoms via a small controller if they improve validation under budget.
    

---

## Guarantees & scope

- **Type-soundness**: decoded models are composition-valid by construction.
    
- **Stability hooks**: per-node stability metadata is tracked and can be penalized/filtered.
    
- **Expressivity (on compact families)**: with a sufficiently rich registry (e.g., signatures + polynomials + spectral atoms), RN features approximate a large class of continuous functionals.
    
- **Non-goals**: RC is **not** a deep-learning framework; it’s a _calculus_ and a _search engine_ that can wrap around PyTorch/JAX ops.

---

## Repo Layout

```
rosetta-calculus/
├─ rosetta/
│  ├─ types/           # type system + ontology utilities
│  ├─ atoms/           # bundled atoms (fft, scattering, signatures, koopman, kme, adapters)
│  ├─ combinators/     # compose, concat, pool, attention, quotient
│  ├─ rn/              # Rosetta Network graph, type-checker, executor
│  ├─ opal/            # typed NAS (differentiable backbone + discrete controller)
│  ├─ metrics/         # stability estimators, cost models, invariance tests
│  └─ registry/        # YAML schema, loaders, validation
├─ examples/
│  ├─ timeseries_synthetic.ipynb
│  ├─ images_scatting2d.ipynb
│  └─ graphs_wavelets.ipynb
├─ tests/              # unit + property tests (pytest + hypothesis)
├─ docs/               # mkdocs site
├─ scripts/            # benchmark runners, profiling, reproducibility
├─ .github/            # actions, templates
├─ pyproject.toml
├─ README.md
├─ CONTRIBUTING.md
├─ CODE_OF_CONDUCT.md
├─ SECURITY.md
└─ CITATION.cff
```

---

## Benchmarks (starter pack)

- **Synthetic separation**: chaotic vs. stochastic time-series (RN features → simple classifier).
    
- **Reconstruction curve**: RN encoder → NN decoder; MSE vs. feature budget (empirical density).
    
- **Stability sweep**: noise/subsampling vs. feature distortion; report empirical Lipschitz.
    
- **Ablations**: types ON/OFF, controller ON/OFF, invariance penalties ON/OFF.
    

Run:

```bash
python scripts/bench_timeseries.py --budget.latency_ms 25 --search.max_epochs 30
```

---

## Contributing

1. **Fork → feature branch → PR.**
    
2. Run **lint + tests** locally: `pre-commit run -a && pytest -q`.
    
3. Add/extend **docstrings and examples**.
    
4. For new atoms, include:
    
    - Typed signature and metadata (diff?, invariance, stability, cost),
        
    - Minimal unit tests (shape, gradient if diff, invariance check),
        
    - One usage example (tiny notebook cell).
        

We follow **semantic versioning** and a lightweight **RFC process** (see `docs/rfc/0001-atom-guidelines.md`).

---

## License

MIT (default). If any bundled atom depends on GPL libraries, isolate it as an optional extra.

---

# Additional recommendations for the repo (beyond the README)

## 1) CI/CD (GitHub Actions)

- **`ci.yml`**: matrix on `py{3.9,3.10,3.11}` and OS (`ubuntu`, `macos`). Steps: cache + install + `pre-commit` + `pytest -q` + `mypy` + `ruff` + `pydocstyle`.
    
- **`docs.yml`**: build & deploy MkDocs to GitHub Pages on `main` tags.
    
- **`release.yml`**: build wheels (cibuildwheel), upload to TestPyPI on tag `v*`, then promote to PyPI via manual approval.
    

## 2) Dev ergonomics

- Use **uv** or **poetry**; ship a locked `requirements-dev.txt`.
    
- Add **pre-commit** hooks: `ruff`, `black`, `isort`, `mypy`, `nbstripout`.
    
- Provide a **DevContainer** (`.devcontainer/`) for one-click VS Code onboarding.
    
- Add **`make` targets**: `make test`, `make lint`, `make docs`, `make bench`.
    

## 3) Docs (mkdocs + mkdocstrings)

- `docs/` with sections: _Overview_, _Concepts (Types/Atoms/Combinators/OPAL)_, _Tutorials_, _API Reference_, _Design Notes_, _RFCs_, _Roadmap_, _FAQ_.
    
- Diagrams: include Mermaid graphs showing typed composition and OPAL’s search loop.
    

## 4) Governance files

- **`CONTRIBUTING.md`** with atom submission checklist and test matrix.
    
- **`CODE_OF_CONDUCT.md`** (Contributor Covenant).
    
- **`SECURITY.md`** with disclosure policy & contact.
    
- **`CITATION.cff`** for citation metadata.
    

## 5) Templates

- **Issues**: bug report, feature request, atom proposal (requires type signature, invariance, stability estimator, cost estimate, minimal test).
    
- **PR template**: includes “Why, What, Tests, Docs, Breaking changes, Screenshots/plots”.
    

## 6) Testing philosophy

- **Property tests** (hypothesis) for combinators (associativity of `concat`, type preservation of `compose`).
    
- **Gradient tests**: finite-difference check for differentiable atoms.
    
- **Invariance tests**: augmentation checks (e.g., time shift) pass within tolerance.
    
- **Golden tests** for registry loading from YAML.
    

## 7) Performance / profiling

- Ship a **cost model** utility to estimate expected FLOPs/latency from registry metadata.
    
- Include a **profiling script** (`scripts/profile_atom.py --atom Scattering1D`) that prints FLOPs/latency on random inputs and caches results.
    

## 8) Roadmap (pin this in `docs/roadmap.md`)

- **v0.1**: Types, minimal atoms (FFT, Scattering1D, Signature2, adapters), RN core, OPAL backbone, TS benchmark.
    
- **v0.2**: Non-diff controller, TDA adapter (Barcode2Vec), graph atoms, image scattering.
    
- **v0.3**: Stability certificates, cross-modal transfer demo, registry growth and plugin API.
    

## 9) Reproducibility

- Fix random seeds; record environment snapshots (`pip freeze`/`uv export`).
    
- Provide **data cards** for any datasets used in examples; keep datasets lightweight or auto-download with checksums.
    

## 10) Packaging

- Keep public API thin (`rosetta.{types,atoms,combinators,rn,opal,registry}`); mark experimental modules under `rosetta.experimental`.
    
- Export typed stubs (`.pyi`) for editor support if feasible.
    

---

Sir, if you want, I can immediately generate:

- a ready-to-commit **repo scaffold** (folders, `pyproject.toml`, Actions, pre-commit config, and this README) as downloadable files, or
    
- a minimal **example notebook** that uses the registry + OPAL on a synthetic time-series task.
    

Tell me which one you prefer and I’ll deliver it now.