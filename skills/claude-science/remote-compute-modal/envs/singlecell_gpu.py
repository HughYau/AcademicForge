"""Single-cell torch stack — scVI-tools + scGPT + scanpy/anndata/cell2location.

torch≥2.5 PyPI wheels bundle CUDA — debian_slim base, no nvidia/cuda image.
scGPT pinned to git main (torchtext-free; PyPI 0.2.4 hard-requires archived
torchtext which forces torch≤2.3). scvi-tools 1.4.2 lifts the numpy<2 cap.

cell2location must be ≥0.1.5: 0.1.4 does `from scvi.nn import one_hot` at
module import time, and that internal symbol was removed in scvi-tools ≥1.2 —
with our scvi-tools==1.4.2 pin it ImportErrors before the user can do anything.
0.1.5 declares scvi-tools>=1.3.0 and imports clean. pip can't catch this: it's
not a version-spec mismatch, it's a removed-internal-symbol regression. Repro
on a build with cell2location<0.1.5:
    python -c "import cell2location"
    → ImportError: cannot import name 'one_hot' from 'scvi.nn'

scGPT is installed `--no-deps` (its requirements cap scvi-tools<1.0), so its
own import-time deps must be re-listed below or `import scgpt` ModuleNotFounds:
  - ipython:  scgpt/utils/util.py does `from IPython import get_ipython`
              unconditionally; pulled in by scgpt/__init__.py
  - datasets: scgpt/scbank/databank.py does `from datasets import Dataset, …`,
              also reached from scgpt/__init__.py

Gotcha: anndata 0.11 has two distinct string-write failures. Nullable
`pd.arrays.StringArray` columns are gated — set
`anndata.settings.allow_write_nullable_strings = True`. Pyarrow-backed
`string[pyarrow]` / `ArrowStringArray` columns (e.g. the obs index from
heart_cell_atlas_subsampled) have NO registered writer at all (anndata
#2377) and the setting does not help — coerce to plain `str`/`category`
before `.write_h5ad()`.

Validated on A100-80GB —
  torch=2.5.1+cu124 cuda=12.4 dev=NVIDIA A100 80GB PCIe
  scanpy=1.11.5 anndata=0.11.4 scvi=1.4.2 scgpt=0.2.5 c2l=0.1.5
  leidenalg=0.10.2 numpy=2.4.4 — ALL_IMPORTS_OK
"""

import modal

META = {
    "packages": ["scvi", "scgpt", "scanpy", "anndata", "cell2location", "torch"],
    "gpu_default": "A100",
    "supersedes": ["scvi", "scgpt"],
    # JOB-time only (see proteomics_jax_gpu for the field contract): the
    # documented workflows run on user-staged checkpoints/inputs only.
    "egress_domains": [],
}

_SCGPT_SHA = "cebd6fae655b9c585a4807daa3ac31bb764f06b4"


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.debian_slim(python_version="3.11")
        # debian_slim has no LANG → Python defaults to ASCII for files/stdout;
        # any em-dash/arrow in agent-authored text raises UnicodeEncodeError.
        .env({"LANG": "C.UTF-8", "LC_ALL": "C.UTF-8", "PYTHONIOENCODING": "utf-8"})
        .apt_install("git")
        .pip_install("torch==2.5.1")
        # scGPT first: its deps cap scvi-tools<1.0. Install --no-deps to
        # keep our pinned scvi-tools intact (scGPT works fine with 1.4.2;
        # the cap is conservative).
        .pip_install(
            f"scgpt @ git+https://github.com/bowang-lab/scGPT@{_SCGPT_SHA}",
            extra_options="--no-deps",
        )
        .pip_install(
            "scanpy==1.11.5",
            "anndata==0.11.4",
            "scvi-tools==1.4.2",
            "cell2location==0.1.5",
            "leidenalg~=0.10",
            "igraph~=0.11",
            "numpy~=2.0",
            # scGPT import-time deps skipped by --no-deps. lint_byoc_envs
            # requires ==/~= pins; ~=2.20 is PEP-440 for ">=2.20, <3" — the
            # constraint we actually want (datasets 3.x renamed APIs scbank
            # touches). ipython~=9.0 matches the validated build (unpinned
            # resolved to 9.x; scgpt only needs the top-level
            # get_ipython() which is stable across 8/9).
            "ipython~=9.0",
            "datasets~=2.20",
        )
        # Import smoke at IMAGE BUILD time (CPU-only — none of these init
        # CUDA on import). Fails the build instead of shipping an image that
        # ImportErrors at runtime. pip exits 0 on all three breaks above
        # (--no-deps gaps and removed-internal-symbol regressions are
        # invisible to the resolver), so this is the only place they surface.
        .run_commands(
            "python -c 'import torch, scanpy, anndata, scvi, scgpt, cell2location'"
        )
    )
    # No HYDRATE: scGPT/scvi checkpoints are task-specific; user picks via
    # scgpt.load_pretrained(...) / scvi.model.X.load(...) at job time.
    return img, {}, {}
