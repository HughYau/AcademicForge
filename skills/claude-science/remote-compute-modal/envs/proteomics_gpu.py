"""Proteomics torch stack — Chai-1 + MMseqs2-GPU + ESM-2 + ProteinMPNN deps.

ProteinMPNN has no PyPI dist — the repo is baked into the image at
/app/proteinmpnn (pinned SHA; no job-time github.com egress needed); this
env provides its torch/numpy/biopython deps. torch 2.5.1 (PyPI
wheels bundle CUDA 12 + cuDNN). chai_lab 0.6.1 declares torch<2.7 so 2.5.1
satisfies it. ESM-2 loads via transformers.EsmModel (upstream fair-esm is
archived). nvidia/cuda runtime base is needed for the mmseqs prebuilt
binary's CUDA libs (debian_slim wouldn't have them on LD_LIBRARY_PATH).

Boltz-2 is in proteomics_boltz_gpu.py — its cuequivariance/CUDA-13/cublas
constraints fight everything else here.
"""

import modal

META = {
    "packages": ["chai_lab", "torch", "transformers", "Bio"],
    "gpu_default": "A100-80GB",
    "supersedes": ["chai_lab", "mmseqs2_gpu", "mpnn", "esm", "transformers_bio"],
    # JOB-time only (see proteomics_jax_gpu for the field contract).
    #   api.colabfold.com         remote MSA server (default --msa-mode).
    #   huggingface.co, *.hf.co   chai_lab + EsmModel weights via the HF Hub CDNs.
    #   chaiassets.com            Chai-1's first-inference components (~5 GB).
    # github.com is deliberately NOT declared: it is a generic write-capable
    # host (the same class the HF hub was dropped from the seed for), and the
    # one consumer — ProteinMPNN — is baked into the image at build time below.
    "egress_domains": [
        "api.colabfold.com",
        "huggingface.co",
        "*.hf.co",
        "chaiassets.com",
    ],
}

_ENV = {"CHAI_DOWNLOADS_DIR": "/weights/chai"}

_MMSEQS_SHA256 = "83969dd5c7d4c32858c2fc9a4d1024c15e8fe5da768ce76e787ab0195ffd64e7"


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.from_registry(
            "nvidia/cuda:12.4.1-runtime-ubuntu22.04", add_python="3.11"
        )
        .apt_install("wget", "git")
        .pip_install("torch==2.5.1")
        .pip_install(
            "chai_lab==0.6.1",
            "transformers==4.46.3",
            "biopython==1.84",
            "numpy==1.26.4",
        )
        .run_commands(
            "wget -q https://github.com/soedinglab/MMseqs2/releases/download/"
            "18-8cc5c/mmseqs-linux-gpu.tar.gz -O /tmp/mm.tar.gz",
            f"echo '{_MMSEQS_SHA256}  /tmp/mm.tar.gz' | sha256sum -c",
            "tar xzf /tmp/mm.tar.gz -C /opt",
            "ln -s /opt/mmseqs/bin/mmseqs /usr/local/bin/mmseqs",
            # ProteinMPNN has no PyPI dist — baked at build (unfenced) so the
            # fenced job needs no github.com egress. Pinned 2026-06-28.
            "git clone https://github.com/dauparas/ProteinMPNN.git"
            " /app/proteinmpnn && git -C /app/proteinmpnn checkout"
            " 8907e6671bfbfc92303b5f79c4b5e6ce47cdef57",
        )
        .env(_ENV)
    )
    vols = {
        "/weights/chai": modal.Volume.from_name(
            "claude-science-chai-weights", create_if_missing=True
        ),
    }
    return img, vols, dict(_ENV)


# chai_lab fetches lazily on first inference; no pre-hydrate.
