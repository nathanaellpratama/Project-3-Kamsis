# ============================================
# Container 2: Snort 3 IDS/IPS + ACL Firewall
# Mode: Hybrid (IDS monitoring + IPS blocking)
# ============================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpcap-dev \
    libpcre3-dev \
    libnet1-dev \
    zlib1g-dev \
    luajit \
    hwloc \
    libdumbnet-dev \
    bison \
    flex \
    liblzma-dev \
    openssl \
    libssl-dev \
    pkg-config \
    libhwloc-dev \
    cmake \
    cpputest \
    libsqlite3-dev \
    uuid-dev \
    libcmocka-dev \
    libnetfilter-queue-dev \
    libmnl-dev \
    autotools-dev \
    libluajit-5.1-dev \
    libunwind-dev \
    libfl-dev \
    git \
    wget \
    curl \
    iptables \
    iproute2 \
    net-tools \
    tcpdump \
    procps \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install libdaq (Data Acquisition library for Snort 3)
WORKDIR /opt
RUN git clone https://github.com/snort3/libdaq.git && \
    cd libdaq && \
    ./bootstrap && \
    ./configure --enable-nfq-module && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install Snort 3
RUN git clone https://github.com/snort3/snort3.git && \
    cd snort3 && \
    ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Create Snort directories
RUN mkdir -p /etc/snort/rules /etc/snort/rules/custom \
    /etc/snort/config /var/log/snort /usr/local/lib/snort_dynamicrules

# Copy configuration files
COPY config/snort.lua /etc/snort/config/snort.lua
COPY config/snort_defaults.lua /etc/snort/config/snort_defaults.lua
COPY rules/ /etc/snort/rules/

# Copy scripts
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Copy ACL rules
COPY acl/ /opt/acl/
RUN chmod +x /opt/acl/*.sh

# Create log directory with proper permissions
RUN touch /var/log/snort/alert_fast.txt && \
    chmod 666 /var/log/snort/alert_fast.txt

WORKDIR /opt

ENTRYPOINT ["/opt/scripts/entrypoint.sh"]
