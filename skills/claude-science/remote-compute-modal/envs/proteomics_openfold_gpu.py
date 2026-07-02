"""OpenFold3 0.4.1 [cuequivariance].

[cuequivariance] extra requires torch>=2.7; openfold3 declares
rdkit + pdbeccdutils itself.

CLI: `run_openfold predict --query-json=<json> --output-dir=<dir>
     --inference-ckpt-path=/weights/checkpoints/of3-p2-155k.pt`

Query JSON shape (NOT AF3-style):
    {"queries": {"<name>": {"chains": [
        {"molecule_type": "protein", "chain_ids": ["A"],
         "sequence": "..."}]}}}

Gotcha: output mmCIF lacks _atom_site.occupancy — Bio.PDB.MMCIFParser
chokes; use gemmi or read B_iso_or_equiv (== per-atom pLDDT) directly.
"""

import modal

META = {
    "packages": ["openfold3", "torch"],
    "gpu_default": "A100-80GB",
    # JOB-time only (see proteomics_jax_gpu for the field contract).
    #   api.colabfold.com   remote MSA server (template *.rcsb.org already
    #                       rides the mirrored local baseline).
    "egress_domains": ["api.colabfold.com"],
}

_ENV = {
    "OPENFOLD_CACHE": "/weights",
    # deepspeed's fp_quantizer.is_compatible() shells to nvcc on import;
    # the runtime base doesn't ship it. Point CUDA_HOME at nothing so the
    # check returns early instead of FileNotFoundError.
    "DS_BUILD_OPS": "0",
    "DS_SKIP_CUDA_CHECK": "1",
    "CUDA_HOME": "",
}
_CKPT_URL = (
    "https://openfold3-data.s3.amazonaws.com/openfold3-parameters/of3-p2-155k.pt"
)
_CKPT_SHA256 = "af09eac4f29cef856633af07558cb143226fe95ebbef2c20921769d4a5f4bee4"


def build(
    *, secrets: dict[str, str] | None = None
) -> tuple["modal.Image", dict[str, "modal.Volume"], dict[str, str]]:
    secrets = secrets or {}
    img = (
        modal.Image.from_registry(
            "nvidia/cuda:12.4.1-runtime-ubuntu22.04", add_python="3.11"
        )
        .apt_install("aria2", "libxrender1", "libxext6", "libexpat1", "gcc")
        # deepspeed's import-time CUDA probe shells `which nvcc` then runs
        # it; CUDA_HOME='' isn't enough — give it a stub that prints a
        # version line so the probe parses cleanly.
        .run_commands(
            "printf '#!/bin/sh\\necho \"Cuda compilation tools, release 12.4\"\\n'"
            " > /usr/local/bin/nvcc && chmod +x /usr/local/bin/nvcc"
        )
        .pip_install("openfold3[cuequivariance]==0.4.1")
        # The default model_config sets use_deepspeed_evo_attention=not _is_rocm
        # → True on CUDA → DS4Sci JIT-compile → dies on the stub nvcc above.
        # Hard-disable it; the cuequivariance triangle kernels are the path
        # that works on this base.
        #
        # Patch with python, NOT `sed -i … $(python3 -c 'import openfold3 …')`:
        # importing the package also imports deepspeed, whose accelerator
        # probe prints a WARNING to STDOUT inside the builder ("Setting
        # accelerator to CPU. If you have GPU …"), so the command
        # substitution handed sed every word of that warning as extra
        # "filenames" and the build died with `sed: can't read [WARNING]`,
        # exit 2 (observed live 2026-06-28). importlib.util.find_spec
        # locates the installed file without importing anything (no
        # side-effect output), and the patch fails LOUDLY — a missing file
        # raises with the real path, a drifted config exits naming the
        # pattern — instead of exiting 2 with garbage filenames or
        # silently building an unpatched image. ONE physical line: Modal
        # renders each run_commands entry as a single Dockerfile RUN, so a
        # multi-line shell string does not parse.
        .run_commands(
            "python3 -c '"
            "import importlib.util, pathlib, sys; "
            'spec = importlib.util.find_spec("openfold3") '
            'or sys.exit("openfold3 is not importable after pip install"); '
            "p = pathlib.Path(spec.origin).parent / "
            '"projects/of3_all_atom/config/model_config.py"; '
            "src = p.read_text(); "
            'old = chr(34) + "use_deepspeed_evo_attention" + chr(34) '
            '+ ": not _is_rocm"; '
            'new = chr(34) + "use_deepspeed_evo_attention" + chr(34) '
            '+ ": False"; '
            'sys.exit(f"patch target not found in {p} - openfold3 '
            'model_config drifted") if old not in src else '
            "p.write_text(src.replace(old, new, 1)); "
            'print(f"patched {p}")'
            "'"
        )
        .env(_ENV)
    )
    vols = {
        "/weights": modal.Volume.from_name(
            "claude-science-openfold3-weights", create_if_missing=True
        ),
    }
    return img, vols, dict(_ENV)


# of3-p2-155k.pt (~2.3 GB). Public S3; alt gated source is hf:OpenFold/OpenFold3
# (accept terms then forward HF_TOKEN via submit_job(credentials=['HF_TOKEN'])).
HYDRATE = (
    "bash",
    "-lc",
    "set -e; mkdir -p /weights/checkpoints; cd /weights/checkpoints; "
    # Gate the skip on integrity, not existence — a preallocated/partial
    # file from a prior interrupted run would otherwise trap us forever.
    f'echo "{_CKPT_SHA256}  of3-p2-155k.pt" | sha256sum -c - 2>/dev/null || '
    "{ rm -f of3-p2-155k.pt; "
    f"  aria2c -x16 -s16 -o of3-p2-155k.pt {_CKPT_URL}; "
    f'  echo "{_CKPT_SHA256}  of3-p2-155k.pt" | sha256sum -c -; }}',
)
