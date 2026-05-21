# SPDX-License-Identifier: GPL-3.0-only
# Caesium Image Compressor Linux AppImage builder
# Repository: https://github.com/<your-username>/caesium-image-compressor

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# 1. 编译工具链
RUN apt-get update && apt-get install -y \
    cmake build-essential curl wget file git \
    python3 python3-pip python3-setuptools \
    libgl1-mesa-dev libxkbcommon-dev libxkbcommon-x11-dev libfontconfig1-dev \
    libdbus-1-dev \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-shm0 \
    libxcb-sync1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 \
    && rm -rf /var/lib/apt/lists/*

# 2. Rust (编译 libcaesium 需要)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 3. aqtinstall + Qt 6.8.2 → 安装到 /opt/Qt
RUN pip3 install aqtinstall
RUN mkdir -p /opt/Qt && cd /opt/Qt && \
    aqt install-qt linux desktop 6.8.2 linux_gcc_64 --modules qtimageformats
ENV QT6_DIR="/opt/Qt/6.8.2/gcc_64"

# 4. linuxdeploy (extract 以避免 Docker 内无 FUSE)
RUN wget -q "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" -O /tmp/ldl.AppImage && \
    chmod +x /tmp/ldl.AppImage && \
    /tmp/ldl.AppImage --appimage-extract && \
    mv squashfs-root /opt/linuxdeploy && \
    ln -sf /opt/linuxdeploy/AppRun /usr/local/bin/linuxdeploy && \
    rm /tmp/ldl.AppImage

# 5. linuxdeploy-plugin-qt
RUN wget -q "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage" -O /tmp/ldl-qt.AppImage && \
    chmod +x /tmp/ldl-qt.AppImage && \
    /tmp/ldl-qt.AppImage --appimage-extract && \
    mv squashfs-root /opt/linuxdeploy-plugin-qt && \
    ln -sf /opt/linuxdeploy-plugin-qt/AppRun /usr/local/bin/linuxdeploy-plugin-qt && \
    rm /tmp/ldl-qt.AppImage
