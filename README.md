# vllm-spark

Custom vLLM container image for NVIDIA DGX Spark (ARM64 Grace Blackwell GB10) with transformers 5.0 support.

## Why This Exists

The stock `vllm/vllm-openai` image pins `transformers < 5.0`, but [GLM-4.7-Flash](https://huggingface.co/zai-org/GLM-4.7-Flash) uses the `glm4_moe_lite` architecture which requires `transformers >= 5.0`. This is tracked as [vLLM issue #34098](https://github.com/vllm-project/vllm/issues/34098).

This Dockerfile extends `vllm/vllm-openai:v0.15.1-aarch64-cu130` with **only** the transformers upgrade -- no other modifications. The base provides vLLM 0.15.1 with native `glm4_moe_lite` model support and CUDA 13.0 for Blackwell.

## Image

```
ghcr.io/3whiskeywhiskey/vllm-spark:latest
```

Tags:
- `latest` -- always points to the most recent build from `main`
- `YYYYMMDD` -- date-based tag for pinning (e.g., `20260217`)
- Short SHA -- git commit hash for traceability

## How CI Works

Push to `main` (Dockerfile or workflow changes) triggers a GitHub Actions build:

1. Sets up QEMU for ARM64 emulation on the x86 runner
2. Builds the Dockerfile targeting `linux/arm64` only
3. Pushes to `ghcr.io/3whiskeywhiskey/vllm-spark` with `latest`, date, and SHA tags
4. Uses GitHub Actions cache to avoid re-pulling the base layer on every build

Manual rebuilds are available via `workflow_dispatch` (Actions tab > Run workflow).

## Usage in Kubernetes

```yaml
containers:
  - name: vllm
    image: ghcr.io/3whiskeywhiskey/vllm-spark:latest
    args:
      - "vllm"
      - "serve"
      - "marksverdhei/GLM-4.7-Flash-FP8"
      - "--gpu-memory-utilization"
      - "0.70"
      - "--max-model-len"
      - "32768"
      - "--served-model-name"
      - "glm-4.7-flash"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "8000"
    resources:
      requests:
        nvidia.com/gpu: "1"
      limits:
        nvidia.com/gpu: "1"
```

## Fallback Options

If this custom build approach fails:

1. **Community pre-built image:** [`avarok/vllm-dgx-spark:v11`](https://huggingface.co/avarok/vllm-dgx-spark) -- includes SM 12.x patches and CUDA graph optimizations. Less transparent build process but actively maintained.

2. **Stock vllm-openai with a different model:** Use `vllm/vllm-openai:v0.15.1-aarch64-cu130` directly with a model that works without transformers 5.0 (e.g., Qwen2.5, Llama 3.3). This avoids the custom image entirely but means not running GLM-4.7-Flash.

## When to Remove This Repo

Once `vllm/vllm-openai` ships with `transformers >= 5.0` bundled, this custom image is no longer needed. At that point:

1. Update Phase 21 K8s manifests to reference the stock image directly
2. Archive this repository
