FROM kasmweb/ubuntu-jammy-desktop:1.18.0
USER root

# Layer 1: Base tools + sudo NOPASSWD
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nano \
        netcat-openbsd \
        software-properties-common \
        wget \
        unzip \
        xz-utils \
        tar && \
    echo 'kasm-user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Layer 2: Audio system deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        audacity \
        libsndfile1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Layer 3: Python 3.10 (UVR5 v5.6 constraint: >=3.7,<3.11)
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3.10-tk \
        python3.10-distutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Layer 4: UVR5 source + venv (SKIPS playsound - BROKEN PACKAGE)
RUN mkdir -p /opt/uvr5 && \
    wget --no-check-certificate \
         "https://sourceforge.net/projects/ult-vocal-remover-uvr.mirror/files/v5.6/v5.6%20-%20UVR%20GUI%20source%20code.tar.gz/download" \
         -O /opt/uvr5.tar.gz && \
    tar -xzvf /opt/uvr5.tar.gz -C /opt/uvr5 --strip-components=1 && \
    rm /opt/uvr5.tar.gz

# Create venv with build deps first
RUN python3.10

# Layer 5: REAPER v7.61
RUN wget https://www.reaper.fm/files/7.x/reaper761_linux_x86_64.tar.xz \
        -O /tmp/reaper.tar.xz && \
    tar -xf /tmp/reaper.tar.xz -C /tmp && \
    /tmp/reaper_linux_x86_64/install-reaper.sh \
        --install /opt/REAPER --integrate-desktop && \
    rm -rf /tmp/reaper*

# Layer 6: ZL Equalizer 2 VST3 (CORRECT URL)
RUN wget https://github.com/ZL-Audio/ZLEqualizer/releases/download/v0.6.2/ZL.Equalizer-0.6.2-Linux-x86_64.zip \
        -O /tmp/zleq.zip && \
    unzip /tmp/zleq.zip -d /tmp/zleq && \
    mkdir -p /usr/lib/vst3 && \
    cp -r /tmp/zleq/*.vst3 /usr/lib/vst3/ 2>/dev/null || true && \
    rm -rf /tmp/zleq* /tmp/zleq.zip

# Layer 7: Desktop shortcuts
RUN printf '[Desktop Entry]\nType=Application\nName=UVR5\nExec=bash -c "source /opt/uvr5/venv/bin/activate && SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True python3.10 /opt/uvr5/UVR.py"\nTerminal=true\n' \
        > /root/Desktop/UVR5.desktop && \
    printf '[Desktop Entry]\nType=Application\nName=REAPER\nExec=/opt/REAPER/reaper\nTerminal=false\n' \
        > /root/Desktop/REAPER.desktop && \
    chmod +x /root/Desktop/UVR5.desktop /root/Desktop/REAPER.desktop

USER 1000
