FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip zstd ffmpeg openssh-server \
    libx11-6 libgl1 libglib2.0-0 libegl1 libgles2 \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://rclone.org/install.sh | bash
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI /app/ComfyUI \
 && pip install --no-cache-dir -r /app/ComfyUI/requirements.txt \
 && pip install --no-cache-dir "huggingface_hub[cli]"
COPY start.sh addmodel.sh getmodel.sh /app/
RUN chmod +x /app/start.sh /app/addmodel.sh /app/getmodel.sh
EXPOSE 8188 22
CMD ["/app/start.sh"]
