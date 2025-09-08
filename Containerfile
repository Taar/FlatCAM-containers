ARG PYTHON_TAG=3.12.11-slim-trixie
ARG DEBIAN_TAG=13.0-slim

# Only used for testing x11 apps
FROM docker.io/library/debian:${DEBIAN_TAG} AS xeyes

LABEL org.opencontainers.image.source=https://github.com/Taar/FlatCAM-containers
LABEL org.opencontainers.image.description="OCI Containers for running FlatCAM"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install \
        git \
        build-essential \
        xserver-xorg-core \
        x11-apps \
        libxkbcommon0 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-shape0 \
        libxcb-util1 \
        libxcb-keysyms1 \
        libglib2.0-0t64 \
        libxkbcommon-x11-0 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m gnuplususer

WORKDIR /home/gnuplususer

USER gnuplususer

CMD xeyes

FROM docker.io/library/python:${PYTHON_TAG} AS base

LABEL org.opencontainers.image.source=https://github.com/Taar/FlatCAM-containers
LABEL org.opencontainers.image.description="OCI Containers for running FlatCAM"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install \
        git \
        build-essential \
        python3-tk \
        libgdal-dev \
        libxkbcommon0 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-shape0 \
        libxcb-util1 \
        libxcb-keysyms1 \
        libgdal36 \
        libglib2.0-0t64 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m gnuplususer

WORKDIR /home/gnuplususer

USER gnuplususer

ARG GIT_HASH=573707ce43545a19fbe738bec6870097240d2452
ARG GIT_BRANCH=mstanciu_Beta_8.995
RUN git clone \
    -b ${GIT_BRANCH} \
    --single-branch \
    https://github.com/dwrobel/flatcam.git && \
    cd flatcam && \
    git -c advice.detachedHead=false checkout ${GIT_HASH} && \
    rm -rf .git

WORKDIR /home/gnuplususer/flatcam

RUN python -m venv .venv

ENV PATH="/home/gnuplususer/flatcam/.venv/bin:$PATH"

# Contians the version pinned Python libraries required by FlatCAM
COPY requirements.in ./

RUN pip install --no-cache -r requirements.in

# Modifies the flatcam.py executable so that it will use the virtual env python
# instead of the system python
RUN sed -i 's/#!\/usr\/bin\/python3/#!\/usr\/bin\/env python/' flatcam.py

# Helps with debugging if a required QT plugin fail to load
# when running the container
ENV QT_DEBUG_PLUGINS=1

CMD ./flatcam.py

# FlatCAM x11 image
FROM base AS xserver

USER root

RUN apt-get -y update && \
    apt-get -y install \
        xserver-xorg-core \
        libxkbcommon-x11-0 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER gnuplususer

# FlatCAM wayland image
FROM xserver AS wayland

USER root

RUN apt-get -y update && \
    apt-get -y install \
        libwayland-dev \
        libwayland-cursor0 \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV XDG_RUNTIME_DIR=/tmp
ENV WAYLAND_DISPLAY=wayland-0
# Gets Qt 6 to use wayland
ENV QT_QPA_PLATFORM=wayland

USER gnuplususer
