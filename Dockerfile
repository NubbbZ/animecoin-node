FROM ubuntu:18.04

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install standard build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libtool \
    autotools-dev \
    automake \
    pkg-config \
    libssl-dev \
    libevent-dev \
    bsdmainutils \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-chrono-dev \
    libboost-program-options-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libminiupnpc-dev \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Compile Berkeley DB 4.8.x from source (Required for the wallet)
RUN wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' \
    && tar -xzvf db-4.8.30.NC.tar.gz \
    && cd db-4.8.30.NC/build_unix/ \
    && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/app/db4 \
    && make install \
    && cd /app \
    && rm -rf db-4.8.30.NC.tar.gz db-4.8.30.NC

# 3. Clone the Animecoin repository into a new directory
RUN git clone https://github.com/Animecointeam/Animecoin.git /app/animecoin

WORKDIR /app/animecoin

# 4. Standard autotools build process
RUN ./autogen.sh \
    && ./configure LDFLAGS="-L/app/db4/lib/" CPPFLAGS="-I/app/db4/include/" --without-gui --disable-tests \
    && make -j$(nproc) \
    && make install

# Create the data directory
RUN mkdir -p /root/.animecoin

# 5. Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Document the default P2P (1212) and RPC (8332) ports
EXPOSE 1212 8332

# Use the entrypoint script to handle configuration
ENTRYPOINT ["entrypoint.sh"]

# Run the daemon in the foreground
CMD ["animecoind", "-printtoconsole"]