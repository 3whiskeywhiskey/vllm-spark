# Custom vLLM container for DGX Spark (ARM64 Blackwell GB10)
#
# WHY: The stock vllm-openai image pins transformers < 5.0, but GLM-4.7-Flash
# uses the glm4_moe_lite architecture which requires transformers >= 5.0.
# This Dockerfile extends the community ARM64 build with the transformers upgrade.
#
# Base: vllm/vllm-openai:v0.15.1-aarch64-cu130
#   - vLLM 0.15.1 (native glm4_moe_lite model support)
#   - CUDA 13.0 (matches DGX Spark driver)
#   - ARM64 native (no QEMU emulation needed at runtime)
#
# References:
#   - vLLM issue #34098: https://github.com/vllm-project/vllm/issues/34098
#   - vLLM Docker Hub: https://hub.docker.com/r/vllm/vllm-openai
#
# TODO: Remove this custom image once vllm-openai ships transformers >= 5.0

FROM vllm/vllm-openai:v0.15.1-aarch64-cu130

# Upgrade transformers to support glm4_moe_lite architecture (GLM-4.7-Flash).
# --force-reinstall: overwrite the pinned versions
# --no-deps: prevents pip from resolving the full dependency tree, which would
#   downgrade or conflict with other pinned packages in the base image.
# huggingface_hub must be upgraded alongside transformers -- transformers main
# imports is_offline_mode which only exists in newer huggingface_hub.
RUN pip install --force-reinstall --no-deps \
    https://github.com/huggingface/transformers/archive/main.tar.gz \
    huggingface_hub
