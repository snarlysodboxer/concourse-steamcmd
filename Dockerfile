FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add multiverse repository for steamcmd
RUN add-apt-repository multiverse && \
    dpkg --add-architecture i386 && \
    apt-get update

# Accept Steam license and install SteamCMD
RUN echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt-get install -y steamcmd && \
    rm -rf /var/lib/apt/lists/*

# Create symlink for easier access
RUN ln -s /usr/games/steamcmd /usr/local/bin/steamcmd

# Create non-root user for running SteamCMD
RUN useradd -U steam -m --shell /usr/bin/bash

# Copy resource scripts (this creates /opt/resource automatically)
COPY assets/ /opt/resource/
RUN chmod +x /opt/resource/*

# Set working directory for debugging convenience
# (Concourse will override workdir during actual resource operations)
WORKDIR /opt/resource

# Initialize SteamCMD as steam user (download initial files)
USER steam
RUN steamcmd +quit

# Switch back to root for resource operations (needed for Concourse permissions)
USER root