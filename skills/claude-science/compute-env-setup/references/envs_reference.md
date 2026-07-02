---
name: compute-envs-reference
description: The Claude Science compute environments as worked examples of the generalized build-spec pattern. Read alongside compute-env-setup. Triggers on "what's in proteomics-gpu", "which env has X", "rebuild <env>", "weight cache for <tool>".
---

# Compute environment reference — worked examples

Each entry is the build-spec that **renders unchanged** through any provider's `render_image`. Validated on two backends (managed-sandbox sm_90, Modal sm_80). Tier defaults and mounts are deploy-spec — listed here for reference, but live in `ENV_TABLE`, not the build dict.

| env | base | weights | sm_90 | tier default |
|---|---|---|---|---|
| dataml-cpu | python:3.12-slim | — | n/a | 4c/16G |
| bio-cpu | python:3.12-slim | — | n/a | 4c/16G |
| chem-cpu | python:3.12-slim | — | n/a | 4c/16G |
| singlecell-cpu | python:3.12-slim | — | n/a | 8c/32G |
| genomics-cpu | python:3.12-slim | — | n/a | 8c/64G |
| imaging-cpu | python:3.12-slim | — | n/a | 4c/32G |
| proteomics-gpu | pytorch:2.7.1-cu128-devel | RO-mount ~19.5G | ✅ | 1gpu/64G |
| proteomics-jax-gpu | colabfold:1.5.5-cu12.2 | RO-mount 4.9G | ✅ | 1gpu/64G |
| genomics-gpu | pytorch:2.7.1-cu128-devel | RO-mount 17G+66G | ✅ | 1gpu/128G |
| singlecell-gpu | pytorch:2.7.1-cu126-**devel** | RO-mount 182M | ✅ | 1gpu/64G |
| torch-geometric-gpu | pytorch:2.7.1-cu126-runtime | — | ✅ | 1gpu/32G |
| diffdock-gpu | pytorch:2.4.1-cu124-devel | RO-mount ~1.6G | ✅ | 1gpu/32G |

---

## CPU envs

All six share `base: python:3.12-slim`. No weight mounts, no egress. Single pip phase. The only per-env decisions are which apt `.so` deps the wheels link against and which CLI binaries to bake.

### dataml-cpu
**apt:** `libgomp1 build-essential`
**pip:** scikit-learn xgboost statsmodels pymc arviz shap umap-learn networkx dask[complete] polars zarr gcsfs s3fs aeon pymoo
**weights:** none
**egress_hosts:** none
**validated:** RF + XGBoost fit on 200×5 → score (1.0, 1.0); polars DataFrame round-trip
**gotchas:** `aeon` PyPI name resolves to a 0.0.0 squatter on some mirrors — pin `aeon>=1.0`. xgboost wheel pulls `nvidia-nccl-cu12` (~200MB dead weight on CPU).

### bio-cpu
**apt:** `libgomp1 build-essential libgl1 libglib2.0-0` — `libglib2.0-0` is for pyopenms `.so`
**pip:** biopython prody biotite scikit-bio pyopenms ete3 cobra neurokit2 FlowIO matchms numpy scipy pandas
**weights:** none
**egress_hosts:** none
**validated:** ubiquitin FASTA → ProtParam → 76aa, MW 8564.7, pI 6.56
**gotchas:** none hit

### chem-cpu
**apt:** `build-essential libxrender1 libxext6 libsm6 libgomp1` — X libs for rdkit's drawing code
**pip:** rdkit openbabel-wheel datamol useful_rdkit_utils molfeat PyTDC aizynthfinder
**weights:** none (aizynthfinder retro data NOT baked — `download_public_data` left for runtime)
**egress_hosts:** none
**validated:** aspirin SMILES → MolWt 180.16, Morgan FP 24 on-bits
**gotchas:** PyTDC transitively pulls torch + jupyter + scanpy + ~250 deps and forces a sklearn-from-source build → ~19 min build, ~5GB image. If you don't need TDC, drop it.

### singlecell-cpu
**apt:** `libgomp1 build-essential`
**pip:** scanpy anndata leidenalg igraph scrublet cellxgene-census samap
**weights:** none
**egress_hosts:** none
**validated:** scanpy normalize+PCA+neighbors+leiden on 100×50 random AnnData → 1 cluster
**gotchas:** louvain dropped (no py3.12 wheel; leidenalg covers it). samap historically pins scanpy<1.10 — drop if it conflicts.

### genomics-cpu
**apt:** `samtools bedtools bwa spades wget bzip2 build-essential libgomp1 libcurl4-openssl-dev libbz2-dev liblzma-dev`
**run_commands:** fetch bwa-mem2 v2.2.1 static binary tarball → `/opt`, symlink dispatcher + arch variants into `/usr/local/bin/`. Debian's apt has only legacy `bwa`, not `bwa-mem2`.
**pip:** pysam deeptools gtars pydeseq2 anndata biopython
**weights:** none
**egress_hosts:** none
**validated:** bwa-mem2 index 800bp ref → align 2 reads → pysam parse SAM (`2.2.1 2`)
**gotchas:** bwa-mem2 has a fixed 3.6GB host-RAM prealloc regardless of ref size — tier needs `mem_gib≥32`.

### imaging-cpu
**apt:** `libopenslide0 libopenslide-dev libvips42 libgl1 libglib2.0-0 build-essential`
**pip:** pydicom pylibjpeg pylibjpeg-libjpeg openslide-python pillow scikit-image
**weights:** none
**egress_hosts:** none
**validated:** sobel filter on 128×128 random uint8 → mean 0.2256; pydicom imports
**gotchas:** histolab dropped (numpy<1.22 pin). openslide-python needs the apt `libopenslide0`, not just the wheel.

---

## GPU envs

### torch-geometric-gpu
**base:** `pytorch/pytorch:2.7.1-cuda12.6-cudnn9-runtime`
**apt:** git build-essential
**pip_phases:**
1. `pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv` with `find_links=https://data.pyg.org/whl/torch-2.7.0+cu126.html` — **find_links not extra_index** (flat HTML, not PEP-503). Wheel URL encodes torch-minor + CUDA; this is why pyg lives in its own env.
2. `torch_geometric` (pure-python, no version coupling)
3. `lightning>=2.2` — Trainer workflows are the common pyg consumer; ship it here so the env is self-contained.
**weights:** none
**egress_hosts:** `github.com raw.githubusercontent.com codeload.github.com data.pyg.org` — `torch_geometric.datasets.*` fetch benchmark data from there
**validated:** GCNConv(8→4) forward → `(4,4)` cuda tensor; KarateClub 2-layer fwd+bwd loss decreases
**gotchas:** isolated specifically because pyg wheels lag torch releases by weeks. Don't merge into proteomics-gpu.

### singlecell-gpu
**base:** `pytorch/pytorch:2.7.1-cuda12.6-cudnn9-devel` — **devel** not runtime: flash-attn compiles via nvcc
**apt:** git build-essential wget ninja-build
**pip_phases:**
1. `scanpy anndata leidenalg igraph squidpy mudata scvi-tools>=1.2`
2. `flash-attn==2.8.0.post2` with `no_build_isolation=True` — `scgpt.tasks.embed_data` defaults `use_fast_transformer=True`
3. `git+https://github.com/bowang-lab/scGPT.git gdown` with `no_deps=True` — PyPI `scgpt==0.2.4` is frozen on the legacy `torchtext.vocab` API; git HEAD has flash-attn-2 compat. `no_deps` because its metadata pins `scvi-tools<1.0` (a fossil).
4. `datasets` — git HEAD imports it at module level; `no_deps` skipped it. **Read `pyproject.toml` for runtime deps** when you `--no-deps` a git package.
5. `scvi-tools>=1.2` with `no_deps=True` — snap scvi back if anything downgraded it
**env:** `JAX_PLATFORM_NAME=cpu` — defensive (scvi 1.4.x dropped jax; if it returns, torch owns the GPU)
**run_commands:** `pip uninstall -y torchtext`; install `torchtext_shim.py` as `torchtext.vocab` via `.pth`; `pip uninstall -y pytorch-lightning` (drop the 1.9.5 alias, keep `lightning` 2.x)
**shim_files:** `torchtext_shim.py → /opt/shims/` — shim must implement: `Vocab.__init__(dict|Vocab)`, `.vocab` property (returns `self`), `__len__/__contains__/__getitem__/__call__`, `lookup_indices/lookup_token/lookup_tokens`, `get_itos/get_stoi`, `set/get_default_index`, `append_token`, **`insert_token`** (GeneVocab.from_dict calls it for specials). torchtext is archived upstream; no wheel for torch≥2.2 will ever exist.
**weights:** RO-mount (182M, scgpt-human raw checkpoint: `args.json best_model.pt vocab.json`). Runtime: pass `model_dir="/datavol/scgpt-human"` directly — **not** HF hub format, no cache env-var.
**egress_hosts:** HF + `drive.google.com drive.usercontent.google.com docs.google.com accounts.google.com` (gdown's consent redirect chain)
**validated:** `GeneVocab.from_file("/datavol/scgpt-human/vocab.json")` → 60697 tokens; `embed_data` on 10×50 → `(10, 512)` embeddings
**gotchas:** **read GeneVocab source first**, don't iterate one missing-method-per-rebuild — the shim grew across four image versions before someone grepped `gene_tokenizer.py` for every `.vocab|self\.\w+\(` call. The "empty stub suffices" claim was wrong: `embed_data` exercises `.vocab`, `insert_token`, `set_default_index`.

### genomics-gpu
**base:** `pytorch/pytorch:2.7.1-cuda12.8-cudnn9-devel` — **devel** not runtime: flash-attn needs nvcc
**apt:** git wget ca-certificates ninja-build build-essential samtools bedtools bwa libcurl4-openssl-dev libbz2-dev liblzma-dev
**pip_phases:**
1. `flash-attn==2.8.0.post2` with `no_build_isolation=True` — must see the base's torch headers. Pinned because that version has a prebuilt cu128 wheel (no 30-min nvcc compile).
2. `evo2 borzoi-pytorch transformers<4.51 einops intervaltree pysam biopython pandas`
**env:** `CUDA_HOME=/usr/local/cuda`
**run_commands:** (1) fetch mmseqs-linux-gpu binary → `/opt/mmseqs`; (2) **bake SwissProt GPU-padded DB at `/db/sprot_gpu`** — wget fasta, `mmseqs createdb` + `makepaddedseqdb`, drop unpadded. ~387MB; image bloat < per-job download.
**weights:** RO-mount BOTH `genomics.squashfs` (evo2_7b, 17G) at `/datavol` AND `genomics-40b.squashfs` (evo2_40b, 66G) at `/datavol40b`. Populate: `HF_HOME=$STAGE/hf python -c 'from huggingface_hub import snapshot_download; snapshot_download("arcinstitute/evo2_7b")'` (and `evo2_40b`). Runtime: `HF_HUB_OFFLINE=1 HF_HOME=/datavol/hf` (or `/datavol40b/hf`).
**egress_hosts:** HF
**validated:** `mmseqs easy-search ubiquitin.fa /db/sprot_gpu hits.m8 /tmp/mm --gpu 1` → 265 hits
**gotchas:** **do NOT use NGC pytorch base** — ships TransformerEngine → evo2 auto-uses FP8 → A100 dies with "compute≥8.9 required". Our devel base has nvcc but no TE → bf16 fallback works on both A100 and H100. Set `HF_HUB_OFFLINE=1` or HF tries to write `.locks/` into the RO mount.

### proteomics-gpu
**base:** `pytorch/pytorch:2.7.1-cuda12.8-cudnn9-devel`
**apt:** git wget ca-certificates build-essential
**pip_phases (the chai/protenix dance — order is load-bearing):**
1. `chai_lab huggingface-hub biopython==1.84` — chai_lab pulls its own torch
2. `torch==2.7.1` with `force_reinstall=True extra_index=…/whl/cu128` — **snap torch back**; chai's pin doesn't match
3. `boltz cuequivariance-torch>=0.1.0 cuequivariance fair-esm deepchem[torch] transformers<5 pytorch-lightning prody>=2.5 biotite mdtraj` — `transformers<5` because deepchem 2.8's ChemBERTa loader uses `tokenization_roberta_fast` (removed in 5.x)
4. `cuequivariance-ops-torch-cu12` — boltz's default fast-kernel path needs the **compiled-ops** package, not just `cuequivariance-torch`. cu12 wheel is runtime-compat across cu12.x.
5. `ml-collections ihm modelcif` — protenix's actual runtime deps (manually listed because of step 6)
6. `protenix` with `no_deps=True` — protenix pins `biopython==1.83`, boltz pins `==1.84`; they conflict, so install protenix last without deps
7. `openfold3==0.4.1` with `no_deps=True` — its full deps pull deepspeed/mkl/cuda-python; we run the cuEq kernel path instead
8. `rdkit pdbeccdutils kalign-python lmdb ijson func_timeout memory_profiler click wandb boto3 awscrt nvidia-cutlass` — openfold3's actual runtime deps. `boto3`/`awscrt` because `openfold3.core.data.io.s3` is **eager-imported** by `_import_all_py_files_from_dir` even when weights are local. `nvidia-cutlass` because the cuEq path still checks for `cutlass_library`.
**env:** `CUDA_HOME=/usr/local/cuda`; `LD_LIBRARY_PATH=<site-packages>/cuequivariance_ops/lib:<site-packages>/nvidia/cuda_nvrtc/lib:$LD_LIBRARY_PATH` — the ops `.so` is RPATH'd to `libcue_ops.so` + `libnvrtc.so.12`, neither on the default loader path. Without this you get `ImportError: libcue_ops.so` even though pip succeeded.
**run_commands:**
- git-clone ProteinMPNN and LigandMPNN to `/app/{proteinmpnn,ligandmpnn}`
- `sed -i 's/np\.int\b/int/g; s/np\.float\b/float/g; s/np\.bool\b/bool/g; s/np\.object\b/object/g' /app/ligandmpnn/openfold/np/residue_constants.py` — the vendored openfold uses removed numpy aliases. **Do not** delete the eager-import line in `__init__.py` instead — it's a list-comp; deleting it leaves `for _m in _modules:` referencing undefined.
- `cd /app/ligandmpnn && bash get_model_params.sh ./model_params` — bake checkpoints (~400MB)
- write the git-tools index under `/opt/`; optionally trigger protenix's first import to bake its JIT `.so` (~189s)
- `apt-get install -y libxrender1 libxext6 libsm6` — rdkit's `Chem.Draw` (pulled by pdbeccdutils → openfold3) needs X11 render libs
- `sed -i` flip `model_config.py` eval defaults `use_deepspeed_evo_attention: not _is_rocm` → `False` and `use_cueq_triangle_kernels` → `True` — DS4Sci is hardcoded on CUDA; **no CLI/`--runner-yaml` override exists** (runner-yaml validates against `InferenceExperimentConfig`, not model config)
**weights:** RO-mount (~19.5G). Contents: `hf/` + `torch/hub/checkpoints/` (esm2 8M+650M), `boltz/` (boltz2_conf/aff.ckpt + mols/, ~7.5G), `chai/` (conformers + models_v2/ + **`esm/` — chai's own 5.3G traced ESM2-3B**, fetched only on first inference, not at install), `openfold3/` (`of3-p2-155k.pt` 2.29G + `ckpt_root` discovery marker). Runtime: `TORCH_HOME=/datavol/torch`, `BOLTZ_CACHE=/datavol/boltz`, `CHAI_DOWNLOADS_DIR=/datavol/chai`, `OPENFOLD_CACHE=/datavol/openfold3` (all RO-safe — `path.exists()` before write; openfold3 auto-discovers via `ckpt_root`, no `--inference-ckpt-path` needed), `HF_HUB_OFFLINE=1 HF_HOME=/datavol/hf`.
**egress_hosts:** HF + `dl.fbaipublicfiles.com files.rcsb.org data.rcsb.org api.colabfold.com`
**validated:** boltz predict (no `--no_kernels`) 20s; chai-lab fold e2e; ligandmpnn 46-residue design; ESM2-8M embed 27aa → `(1,29,320)`; openfold3 ubiquitin MSA-free → 5× `.cif` (pLDDT 78.96 / pTM 0.667) 28s
**gotchas:** the first weight build had `boltz/` and `chai/` **empty** because the populate script had `|| echo "non-fatal"` around the download — `du -sh` per-subdir before snapshot. If step 2 is skipped you silently run whatever torch chai pulled (CVE-gated `torch.load` may fire). If step 6 isn't `no_deps`, biopython conflict aborts the whole phase. ProteinMPNN must be `cd /app/proteinmpnn` first (relative imports). Step 8's pdbeccdutils bumps `gemmi` to 0.7.x and `scipy` to 1.17.x — boltz/chai pin-warn but run fine; re-validate boltz e2e after any rebuild.

### proteomics-jax-gpu
**base:** `ghcr.io/sokrypton/colabfold:1.5.5-cuda12.2.2` — colabfold env pre-baked at `/usr/local/envs/colabfold` (py3.9)
**apt:** wget ca-certificates git bzip2
**pip_phases:**
1. `'jax[cuda12]>=0.4.26,<0.5' numpy<2 dm-haiku<0.0.13` — **upgrade jaxlib to a build with sm_90 PTX**. Base ships jax 0.4.20 whose jaxlib lacks Hopper cubins → `CUDA_ERROR_INVALID_IMAGE` on sm_90 GPUs. The cuda12 wheels bundle their own libs so the base's 12.2 toolkit doesn't matter. `<0.5` avoids `tree_util` API churn that breaks alphafold's haiku model code; `dm-haiku<0.0.13` because 0.0.13+ uses `bool|None` syntax (py3.10+) and colabfold env is py3.9.
**env:** `XLA_PYTHON_CLIENT_MEM_FRACTION=0.9 TF_FORCE_UNIFIED_MEMORY=0` — gVisor's GPU mem detection is wrong; without these JAX OOMs at compile.
**weights:** RO-mount `jax.squashfs` (4.9G) — 16 alphafold params `.npz` + **`download_finished.txt` and `download_complexes_multimer_v3_finished.txt` markers** (colabfold checks the markers, not the `.npz` files). Populate: extract `alphafold_params_2022-12-06.tar` to `$STAGE/colabfold/params/` then `touch` the two markers. Runtime: `colabfold_batch in.fa out/ --data /datavol/colabfold`.
**egress_hosts:** `api.colabfold.com storage.googleapis.com` + HF — colabfold's MMseqs2 MSA server and AF param tarballs
**validated:** Trp-cage (20aa) single_sequence fold → pLDDT 74.2, PDB written, ~25s
**gotchas:** without the marker files colabfold tries to re-download into the RO mount → `OSError [Errno 30]`. Without the jaxlib upgrade you get `CUDA_ERROR_INVALID_IMAGE` even though `jax.devices()` shows the GPU.


### diffdock-gpu (from-source for sm_90)
**base:** `pytorch/pytorch:2.4.1-cuda12.4-cudnn9-devel` (digest-pinned). Upstream `rbgcsail/diffdock` is torch 1.13.1+cu117 (no sm_90) and runs as `USER appuser` with a micromamba env.
**apt:** git wget ca-certificates build-essential
**pip_phases:**
1. `torch_geometric`
2. `pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv` with `find_links=https://data.pyg.org/whl/torch-2.4.0+cu124.html`
3. `rdkit scipy networkx biopython<2 biopandas e3nn==0.5.1 spyrmsd pyyaml pandas prody fair-esm transformers<4.51 accelerate huggingface-hub gradio requests`
**run_commands:**
- git-clone DiffDock @ pinned SHA → `/app/DiffDock`; set `PYTHONPATH=/app/DiffDock`
- `sed -i 's/(64000, rlimit\[1\])/(min(64000, rlimit[1]), rlimit[1])/' /app/DiffDock/inference.py` — hard-coded `setrlimit(NOFILE, 64000)` exceeds gVisor/cgroup hard limit (typically 20000) → `ValueError` before any work
- `sed -i 's|\./workdir/v1.1|/datavol/workdir/v1.1|g' /app/DiffDock/default_inference_args.yaml` — `inference.py` loads the YAML **after** argparse and overwrites every key, so passing `--model_dir` on CLI is a no-op. Point the yaml at the mount.
- `cd /app/DiffDock && python3 -c 'import utils.so3, utils.torus'` — pre-bake SO(2)/SO(3) lookup `.npy` caches into the image layer. Without this every job recomputes them (~15 min); after, e2e wall went 1048s → 230s.
**weights:** RO-mount (~1.6G) — `workdir/v1.1/{score_model,confidence_model}/` + `torch/hub/checkpoints/esm2_t33_650M_UR50D*.pt` (DiffDock's embedding step needs ESM2-650M). Runtime: `cd /app/DiffDock && TORCH_HOME=/datavol/torch python3 -m inference --config default_inference_args.yaml --protein_path … --ligand_description … --out_dir /work/out`. No `cp -r` needed once the yaml points at the mount.
**egress_hosts:** HF + `dl.fbaipublicfiles.com files.rcsb.org github.com codeload.github.com raw.githubusercontent.com objects.githubusercontent.com` (torch.hub fetches the ESM repo zip via codeload)
**validated:** dock 1CRN + benzamidine SMILES → 10 ranked SDFs, rank1 conf −0.25, 230s wall
**gotchas:** `--config` overwrites CLI for every key in the YAML — to change `samples_per_complex` etc., edit a yaml copy; CLI flags are silently ignored. Real flag is `--ligand_description`, not `--ligand` (the latter only works via argparse prefix-abbreviation). If you see `python3: not found` you're on the upstream image — that one needs `micromamba run -n diffdock python …` and lives at `/home/appuser/DiffDock`.
