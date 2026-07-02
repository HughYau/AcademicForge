"""Cheminformatics torch stack — DeepChem + RDKit + molfeat.

torch≥2.5 PyPI wheels bundle CUDA — debian_slim base, no nvidia/cuda image.
deepchem 2.8.0 is the only PyPI release; it caps python<3.12 (hence py3.11)
but not numpy. libxrender1/libxext6 are for RDKit's drawing code.
"""

import modal

META = {
    "packages": ["deepchem", "rdkit", "molfeat", "torch"],
    "gpu_default": "A100",
    "supersedes": ["deepchem"],
    # JOB-time only (see proteomics_jax_gpu for the field contract): the
    # documented workflows run on staged input files only.
    "egress_domains": [],
}


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.debian_slim(python_version="3.11")
        .apt_install("libxrender1", "libxext6")
        .pip_install("torch==2.5.1")
        .pip_install(
            "rdkit==2024.3.5",
            "deepchem==2.8.0",
            "molfeat==0.10.1",
            "numpy~=2.0",
        )
    )
    return img, {}, {}
