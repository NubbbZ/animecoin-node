#!/bin/bash
set -e

CONF_DIR="/root/.animecoin"
CONF_FILE="$CONF_DIR/animecoin.conf"

# Ensure the config directory exists
mkdir -p "$CONF_DIR"

# Generate the base animecoin.conf file using default port 1212
cat <<EOF > "$CONF_FILE"
port=${PORT:-1212}
listen=1
EOF

# Conditionally enable RPC using default port 8332 only if both USER and PASSWORD are set
if [ -n "$RPC_USER" ] && [ -n "$RPC_PASSWORD" ]; then
    echo "server=1" >> "$CONF_FILE"
    echo "rpcuser=$RPC_USER" >> "$CONF_FILE"
    echo "rpcpassword=$RPC_PASSWORD" >> "$CONF_FILE"
    echo "rpcallowip=${RPC_ALLOW_IP:-127.0.0.1}" >> "$CONF_FILE"
    echo "rpcport=${RPC_PORT:-8332}" >> "$CONF_FILE"
else
    # Disable the RPC server if credentials are not provided
    echo "server=0" >> "$CONF_FILE"
fi

# Conditionally append txindex only if the user explicitly sets it
if [ -n "$TXINDEX" ]; then
    echo "txindex=$TXINDEX" >> "$CONF_FILE"
fi

# If the user provides a comma-separated list of nodes to add, append them
if [ -n "$ADDNODES" ]; then
    IFS=',' read -ra ADDR <<< "$ADDNODES"
    for node in "${ADDR[@]}"; do
        echo "addnode=$node" >> "$CONF_FILE"
    done
fi

# Execute the main command passed from the Dockerfile's CMD
exec "$@"