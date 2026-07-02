"""Shared image for diffdock / rfdiffusion — both torch 2.1.2 on cu12.1.
DiffDock imports torch_cluster/scatter/sparse directly (PyG's native
fallback isn't enough), so the data.pyg.org cu121 wheels are kept;
DGL still needs the data.dgl.ai cu wheel for SE3Transformer. prody only
ships a cp312 wheel — py3.11 compiles from source. Both upstream repos
cloned to /opt at pinned SHAs.

CLI:
    cd /opt/diffdock && python -m inference --config default_inference_args.yaml \\
        --protein_ligand_csv input.csv --out_dir results/
    /opt/rfd/scripts/run_inference.py 'contigmap.contigs=[...]' \\
        inference.output_prefix=/work/out/ inference.model_directory_path=/weights

DiffDock's first run precomputes SO(3) lookup tables (~11 min, silent) and
needs >32 GB host RAM — pass provider_params.modal.memory >= 65536 or it
SIGKILLs mid-precompute.

For the full design pipeline (RFdiffusion → ProteinMPNN → relax+score):
PyRosetta is not bundled (license-gated). Install it in-job with the
user's pyrosetta.org credentials, or use OSS approximations
(freesasa/mdtraj) for SASA and clash-QC.
"""

import modal

META = {
    "packages": [
        "torch",
        "torch_geometric",
        "dgl",
        "e3nn",
        "rdkit",
        "scipy",
        "Bio",
        "hydra",
        "se3_transformer",
        "rfdiffusion",
    ],
    "gpu_default": "A100",
    "supersedes": ["diffdock", "rfdiffusion"],
    # JOB-time only (see proteomics_jax_gpu for the field contract).
    #   dl.fbaipublicfiles.com   DiffDock's fair-esm weights download on
    #                            first inference (RFD checkpoints are hydrated).
    "egress_domains": ["dl.fbaipublicfiles.com"],
}

_DIFFDOCK_SHA = "9a22cbcbc7612c7565c80e8399d9be298971f156"  # v1.1.3
_RFD_SHA = "2d0c003df46b9db41d119321f15403dec3716cd9"
_WEIGHTS_URL = "https://files.ipd.uw.edu/pub/RFdiffusion/"


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.from_registry(
            "nvidia/cuda:12.1.1-runtime-ubuntu22.04", add_python="3.11"
        )
        .apt_install("git", "wget", "build-essential")
        # python-build-standalone (Modal's add_python) sets CXX=clang++; the
        # cuda base only has g++. prody compiles a C ext (cp312-only wheel).
        .env({"CC": "gcc", "CXX": "g++"})
        .pip_install("torch==2.1.2", "numpy~=1.26.4", "pandas~=2.1.4")
        # PyG 2.6 has native fallbacks but DiffDock imports torch_cluster /
        # torch_scatter / torch_sparse directly — keep the cu121 wheels.
        .pip_install(
            "torch-geometric==2.6.1",
            "torch-scatter==2.1.2",
            "torch-sparse==0.6.18",
            "torch-cluster==1.6.3",
            find_links="https://data.pyg.org/whl/torch-2.1.0+cu121.html",
        )
        .pip_install(
            "dgl==1.1.3",
            find_links="https://data.dgl.ai/wheels/cu121/repo.html",
        )
        .pip_install(
            "e3nn==0.5.1",
            "hydra-core==1.3.2",
            "pyrsistent==0.20.0",
            "rdkit==2024.3.5",
            "scipy==1.13.1",
            "biopython==1.79",
            "fair-esm==2.0.0",
            "networkx==3.2.1",
            "pyyaml==6.0.1",
            "prody==2.6.1",
        )
        .run_commands(
            "git init /opt/diffdock && cd /opt/diffdock && "
            "git remote add origin https://github.com/gcorso/DiffDock.git && "
            f"git fetch --depth 1 origin {_DIFFDOCK_SHA} && "
            "git checkout FETCH_HEAD",
            "git init /opt/rfd && cd /opt/rfd && "
            "git remote add origin "
            "https://github.com/RosettaCommons/RFdiffusion.git && "
            f"git fetch --depth 1 origin {_RFD_SHA} && "
            "git checkout FETCH_HEAD",
            "cd /opt/rfd/env/SE3Transformer && pip install --no-deps .",
            "cd /opt/rfd && pip install --no-deps .",
        )
    )
    vols = {
        "/weights": modal.Volume.from_name(
            "claude-science-rfdiffusion-weights", create_if_missing=True
        ),
    }
    return img, vols, {}


# RFdiffusion model weights from files.ipd.uw.edu.
# `wget -qc` resumes partial downloads (so a prior interrupted fetch is
# completed, not skipped); upstream publishes no per-file sha256 — gate on
# torch.load readability instead so a corrupt/truncated file is re-fetched.
HYDRATE = (
    "bash",
    "-lc",
    "set -e; mkdir -p /weights; cd /weights; "
    "for f in Base_ckpt.pt Complex_base_ckpt.pt InpaintSeq_ckpt.pt "
    "InpaintSeq_Fold_ckpt.pt ActiveSite_ckpt.pt Base_epoch8_ckpt.pt "
    "Complex_Fold_base_ckpt.pt; do "
    # torch.serialization.add_safe_globals needs torch>=2.4; this env pins
    # 2.1.2. Just probe the zip header — official RFdiffusion weights from
    # a fixed URL, integrity check is "did the download finish", not pickle
    # safety.
    '  python -c "import zipfile,sys; '
    "  sys.exit(0 if zipfile.is_zipfile('$f') else 1)\" 2>/dev/null || "
    f'  {{ rm -f "$f"; wget -qc {_WEIGHTS_URL}"$f"; }}; done',
)
