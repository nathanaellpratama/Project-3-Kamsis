# ============================================
# Container 3: User / Attacker Client
# Base: Kali Linux Rolling
# Tools: curl, nmap, hping3, sqlmap, nikto
# ============================================
FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Install security testing tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    nmap \
    hping3 \
    sqlmap \
    nikto \
    python3 \
    python3-pip \
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    tcpdump \
    hydra \
    dirb \
    nano \
    less \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create scripts directory
RUN mkdir -p /opt/scripts /opt/tools

# Copy test scripts
COPY scripts/ /opt/scripts/
COPY tools/ /opt/tools/

# Make scripts executable
RUN chmod +x /opt/scripts/*.sh /opt/tools/*.sh

WORKDIR /opt

# Keep container running
CMD ["/bin/bash"]
