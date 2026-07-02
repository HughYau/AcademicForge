"""ColabFold 1.6.1 + jax 0.5.x/cu12 (PyPI plugin model — no version archaeology)."""

import modal

META = {
    "packages": ["colabfold", "jax", "alphafold"],
    "gpu_default": "A100",
    # egress_domains: hosts this env's DOCUMENTED commands dial at JOB time
    # (never hydrate-time hosts — HYDRATE runs in the trusted
    # compute_provider kernel). build_env() returns the list; the host
    # validates, merges and discloses it on the byoc_submit card.
    #   api.colabfold.com   colabfold_batch's default --msa-mode MSA server.
    "egress_domains": ["api.colabfold.com"],
}

_ENV = {
    "JAX_COMPILATION_CACHE_DIR": "/root/.cache/jax",
    "TF_FORCE_UNIFIED_MEMORY": "0",
    "XLA_PYTHON_CLIENT_MEM_FRACTION": "0.95",
    "JAX_PLATFORMS": "cuda",
}


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.from_registry(
            "nvidia/cuda:12.4.1-runtime-ubuntu22.04", add_python="3.11"
        )
        .apt_install("aria2")
        .pip_install(
            "colabfold[alphafold-minus-jax]==1.6.1",
            "jax==0.5.3",
            # jax[cuda12] requests `jax-cuda12-plugin[with_cuda]` (underscore);
            # the wheel declares `with-cuda` (hyphen). Older pip in Modal's
            # add_python image doesn't PEP-685-normalize → nvidia-* not pulled.
            # Spell the extra correctly here instead.
            "jax-cuda12-plugin[with-cuda]==0.5.3",
        )
        # colabfold/batch.py hardcodes TF_FORCE_UNIFIED_MEMORY=1 +
        # XLA_PYTHON_CLIENT_MEM_FRACTION=4.0 on import. Modal's gVisor
        # sandbox doesn't support cudaMallocManaged (UVM), so jax's
        # device_put loops indefinitely allocating host RAM during AF2
        # param load. Patch the values out — caps at real GPU RAM (fine
        # for monomers ≤~1500aa on A100-40GB; use H100-80GB for larger).
        .run_commands(
            "python3 -c 'import colabfold.batch as b; print(b.__file__)' | "
            "xargs sed -i "
            '-e \'s/TF_FORCE_UNIFIED_MEMORY"] = "1"/TF_FORCE_UNIFIED_MEMORY"] = "0"/\' '
            '-e \'s/XLA_PYTHON_CLIENT_MEM_FRACTION"] = "4.0"/XLA_PYTHON_CLIENT_MEM_FRACTION"] = "0.95"/\''
        )
        .env(_ENV)
    )
    vols = {
        "/root/.cache/colabfold": modal.Volume.from_name(
            "claude-science-colabfold-weights", create_if_missing=True
        ),
        "/root/.cache/jax": modal.Volume.from_name(
            "claude-science-colabfold-jax-cache", create_if_missing=True
        ),
    }
    return img, vols, dict(_ENV)


# AlphaFold2 params (~5 GB). Idempotent — colabfold.download skips files it has.
HYDRATE = ("python", "-m", "colabfold.download")
