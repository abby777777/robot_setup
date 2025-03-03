# BASE_IMAGE is fixed to this verified rocm/pytorch release

FROM rocm/pytorch:rocm6.3.3_ubuntu22.04_py3.10_pytorch_release_2.4.0

# Install LeRobot
WORKDIR /ryzers

# lerobot verified against 8861546 (Mar 1, 2025)
RUN git clone https://github.com/huggingface/lerobot && \  
    cd lerobot && sed -i 's/torchvision>=0.21.0/torchvision/g' pyproject.toml && \
    pip install --no-cache-dir ".[aloha, pusht, dynamixel]"

# handle add the render group
RUN groupadd -f render
RUN usermod -aG render root

# Set EGL as the rendering backend for MuJoCo
ENV MUJOCO_GL="egl"


COPY test.sh /ryzers/test.sh
RUN chmod +x /ryzers/test.sh

CMD ["/bin/bash", "-c", "/ryzers/test.sh && exec /bin/bash"]



# sudo docker run  -it --rm --shm-size 16G \

# --cap-add=SYS_PTRACE  --network=host \

# --ipc=host -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \

# --device=/dev/kfd --device=/dev/dri \

# --security-opt seccomp=unconfined --group-add video \

# --group-add render  -e DISPLAY=$DISPLAY \

# -v /tmp/.X11-unix:/tmp/.X11-unix ryzerdocker


