"""Boltz-2 structure prediction.

Standalone because boltz[cuda]'s cuequivariance dependency forces a torch /
nvidia-cublas / CUDA-toolkit version set that conflicts with the rest of
the proteomics stack. Let it have what it wants here.
"""

import modal

META = {
    "packages": ["boltz", "torch"],
    "gpu_default": "A100-80GB",
    # JOB-time only (see proteomics_jax_gpu for the field contract).
    #   api.colabfold.com          boltz's default MSA server.
    #   model-gateway.boltz.bio    `boltz predict` self-downloads its model/CCD.
    #   huggingface.co, *.hf.co    those downloads come via the HF Hub CDNs.
    "egress_domains": [
        "api.colabfold.com",
        "model-gateway.boltz.bio",
        "huggingface.co",
        "*.hf.co",
    ],
}


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    # No constraints, no system CUDA — let boltz[cuda] pull whatever
    # torch + cuequivariance + nvidia-* wheels it resolves to. The
    # cublas≥12.5 floor (cuequiv) vs torch≤2.6's ==12.4.5.8 pin is
    # irreconcilable; the only stable point is torch's own latest with
    # its bundled CUDA libs. debian_slim has no /usr/local/cuda to
    # conflict with the pip-installed nvidia-* packages.
    img = (
        modal.Image.debian_slim(python_version="3.11")
        .pip_install("numpy==1.26.4")
        .pip_install("boltz[cuda]==2.2.1")
        # The new nvidia-cuda-nvrtc package (no -cu12 suffix) installs to
        # nvidia/cu13/lib/, not nvidia/cuda_nvrtc/lib/ where torch's loader
        # looks. cuequivariance's JIT needs libnvrtc-builtins.so.13.0 from
        # there.
        .env(
            {
                "LD_LIBRARY_PATH": (
                    "/usr/local/lib/python3.11/site-packages/nvidia/cu13/lib"
                )
            }
        )
    )
    vols = {
        "/root/.boltz": modal.Volume.from_name(
            "claude-science-boltz-cache", create_if_missing=True
        ),
    }
    return img, vols, {}


# Boltz-2 model + CCD → /root/.boltz.
HYDRATE = (
    "python",
    "-c",
    "from boltz.main import download_boltz2; "
    "from pathlib import Path; download_boltz2(Path('/root/.boltz'))",
)
