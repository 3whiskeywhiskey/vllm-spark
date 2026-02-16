# Custom vLLM container for DGX Spark (ARM64 Blackwell GB10)
#
# WHY: NGC vLLM 26.01-py3 pins transformers < 5.0, but GLM-4.7-Flash
# uses the glm4_moe_lite architecture which requires transformers >= 5.0.
# This Dockerfile extends the NGC base with ONLY the transformers upgrade.
#
# MUST be built for ARM64 (DGX Spark is ARM64 Grace Blackwell).
# GitHub Actions builds via QEMU emulation and pushes to ghcr.io.
#
# References:
#   - vLLM issue #34098: https://github.com/vllm-project/vllm/issues/34098
#   - NGC vLLM container: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/vllm
#   - eugr/spark-vllm-docker: https://github.com/eugr/spark-vllm-docker
#
# TODO: Remove this custom image once NGC ships transformers >= 5.0

FROM nvcr.io/nvidia/vllm:26.01-py3

# Upgrade transformers to support glm4_moe_lite architecture (GLM-4.7-Flash).
# --force-reinstall: overwrite the NGC-pinned version
# --no-deps: CRITICAL -- prevents pip from resolving the full dependency tree,
#   which would downgrade or conflict with NGC-pinned packages (tokenizers,
#   safetensors, huggingface-hub, etc. are already compatible in the base).
RUN pip install --force-reinstall --no-deps \
    git+https://github.com/huggingface/transformers.git@main

# Do NOT install flash-attn (FlashInfer 0.6.0 in NGC base is correct for Blackwell)
# Do NOT set --enforce-eager (CUDA graphs work on sm_121 with vLLM >= 0.13.0)
# Keep default CMD/ENTRYPOINT from NGC base (runs vllm serve)
