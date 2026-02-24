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

# Layer 4: UVR5 source + venv + Matchering + Transkun (FULLY FIXED)
COPY uvr5_gui_v5.6.tar.gz /opt/uvr5.tar.gz
RUN mkdir -p /opt/uvr5 && \
    tar -xzvf /opt/uvr5.tar.gz -C /opt/uvr5 --strip-components=1 && \
    rm /opt/uvr5.tar.gz

# Create venv and pre-install build dependencies FIRST
RUN python3.10 -m venv /opt/uvr5/venv && \
    . /opt/uvr5/venv/bin/activate && \
    pip install --upgrade pip setuptools wheel Cython && \
    # Pre-install scikit-learn to avoid deprecated sklearn conflict
    pip install scikit-learn && \
    # Export sklearn env var BEFORE requirements.txt
    export SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True && \
    # Install requirements with no-cache to avoid corrupted wheels
    pip install --no-cache-dir -r /opt/uvr5/requirements.txt && \
    # Install additional packages
    pip install --no-cache-dir torch==2.5.0 matchering transkun && \
    chown -R 1000:0 /opt/uvr5

# Layer 5: REAPER v7.61
RUN wget https://www.reaper.fm/files/7.x/reaper761_linux_x86_64.tar.xz \
        -O /tmp/reaper.tar.xz && \
    tar -xf /tmp/reaper.tar.xz -C /tmp && \
    /tmp/reaper_linux_x86_64/install-reaper.sh \
        --install /opt/REAPER --integrate-desktop && \
    rm -rf /tmp/reaper*

# Layer 6: ZL Equalizer 2 VST3
RUN wget https://github.com/ZL-Audio/ZLEqualizer/releases/download/v1.1.0/ZL.Equalizer.2-1.1.0-Linux-x86.zip \
        -O /tmp/zleq.zip && \
    unzip /tmp/zleq.zip -d /tmp/zleq && \
    mkdir -p /usr/lib/vst3 && \
    cp -r /tmp/zleq/*.vst3 /usr/lib/vst3/ && \
    rm -rf /tmp/zleq*

# Layer 7: Desktop shortcuts
RUN printf '[Desktop Entry]\nType=Application\nName=UVR5\nExec=bash -c "source /opt/uvr5/venv/bin/activate && SKLEARN_ALLOW_DEPRECATED_SKLEARN_PACKAGE_INSTALL=True python3.10 /opt/uvr5/UVR.py"\nTerminal=true\n' \
        > /root/Desktop/UVR5.desktop && \
    printf '[Desktop Entry]\nType=Application\nName=REAPER\nExec=/opt/REAPER/reaper\nTerminal=false\n' \
        > /root/Desktop/REAPER.desktop && \
    chmod +x /root/Desktop/UVR5.desktop /root/Desktop/REAPER.desktop

USER 1000
