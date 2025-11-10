#!/bin/bash

# Whilst this repo is still private, ensure you set TOKEN to access GH API

# BEGIN - AUTO GENERATED DO NOT EDIT
RUNTIME_RELEASE=2025.11.09.1813
AGENT_RELEASE=2025.11.10.0715
AGENT_ASSET_ID=314601916
RUNTIME_ASSET_ID_LINUX_X64=
RUNTIME_ASSET_ID_LINUX_AARCH64=
RUNTIME_ASSET_ID_DARWIN_X64=
RUNTIME_ASSET_ID_DARWIN_AARCH64=
RUNTIME_ASSET_ID_WINDOWS_AMD64=
# END - AUTO GENERATED DO NOT EDIT

# First: Detect the host OS and platform
detect_platform() {
    local os=""
    local arch=""

    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="linux";;
        Darwin*)    os="darwin";;
        *)          echo "Unsupported OS: $(uname -s)"; exit 1;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="x64";;
        aarch64|arm64)  arch="aarch64";;
        *)              echo "Unsupported architecture: $(uname -m)"; exit 1;;
    esac

    echo "${os}-${arch}"
}

PLATFORM=$(detect_platform)
echo "Detected platform: $PLATFORM"

# Second: Set appropriate asset ID based on platform
case "$PLATFORM" in
    linux-x64)
        RUNTIME_ASSET_ID=$RUNTIME_ASSET_ID_LINUX_X64
        ;;
    linux-aarch64)
        RUNTIME_ASSET_ID=$RUNTIME_ASSET_ID_LINUX_AARCH64
        ;;
    darwin-x64)
        RUNTIME_ASSET_ID=$RUNTIME_ASSET_ID_DARWIN_X64
        ;;
    darwin-aarch64)
        RUNTIME_ASSET_ID=$RUNTIME_ASSET_ID_DARWIN_AARCH64
        ;;
    *)
        echo "Unsupported platform: $PLATFORM"
        exit 1
        ;;
esac

echo "Using RUNTIME_ASSET_ID: $RUNTIME_ASSET_ID"

# Third: Check for the presence of runtime finished file
RUNTIME_FINISHED_FILE="$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/finished"

# Fourth: Download and extract runtime if not already done
if [ -f "$RUNTIME_FINISHED_FILE" ]; then
    echo "Runtime $RUNTIME_RELEASE already installed, skipping download."
else
    echo "Downloading runtime $RUNTIME_RELEASE..."

    # Create directories
    mkdir -p "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"
    mkdir -p "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"

    # Download runtime
    curl -L \
        -H "Accept: application/octet-stream" \
        -H "Authorization: Bearer $TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -o "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz" \
        "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$RUNTIME_ASSET_ID"

    if [ $? -eq 0 ]; then
        echo "Extracting runtime..."
        tar -xzf "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz" -C "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"

        if [ $? -eq 0 ]; then
            # Delete tar.gz
            rm "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz"

            # Write finished file
            touch "$RUNTIME_FINISHED_FILE"
            echo "Runtime installation completed successfully."
        else
            echo "Failed to extract runtime."
            exit 1
        fi
    else
        echo "Failed to download runtime."
        exit 1
    fi
fi

# Fifth: Check for the presence of agent finished file
AGENT_FINISHED_FILE="$HOME/.kerno/assets/agent/$AGENT_RELEASE/finished"

# Sixth: Download and extract agent if not already done
if [ -f "$AGENT_FINISHED_FILE" ]; then
    echo "Agent $AGENT_RELEASE already installed, skipping download."
else
    echo "Downloading agent $AGENT_RELEASE..."

    # Create directories
    mkdir -p "$HOME/.kerno/assets/agent/$AGENT_RELEASE"

    # Download agent
    curl -L \
        -H "Accept: application/octet-stream" \
        -H "Authorization: Bearer $TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -o "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz" \
        "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$AGENT_ASSET_ID"

    if [ $? -eq 0 ]; then
        echo "Extracting agent..."
        tar -xzf "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz" -C "$HOME/.kerno/assets/agent/$AGENT_RELEASE"

        if [ $? -eq 0 ]; then
            # Delete tar.gz
            rm "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz"

            # Write finished file
            touch "$AGENT_FINISHED_FILE"

            # Write startup script
            STARTUP_SCRIPT="$HOME/.kerno/assets/agent/$AGENT_RELEASE/startup.sh"
            cat > "$STARTUP_SCRIPT" << 'EOF'
            #!/bin/bash

            export JAVA_HOME=$HOME/.kerno/assets/runtime/RUNTIME_VERSION_PLACEHOLDER/custom-jre
            "$HOME"/.kerno/assets/agent/AGENT_VERSION_PLACEHOLDER/aicore-agent/bin/aicore-agent
EOF

            sed -i "s|RUNTIME_VERSION_PLACEHOLDER|$RUNTIME_RELEASE|g" "$STARTUP_SCRIPT"
            sed -i "s|AGENT_VERSION_PLACEHOLDER|$AGENT_RELEASE|g" "$STARTUP_SCRIPT"

            # Make it executable
            chmod +x "$STARTUP_SCRIPT"

            echo "Agent installation completed successfully."
        else
            echo "Failed to extract agent."
            exit 1
        fi
    else
        echo "Failed to download agent."
        exit 1
    fi
fi

echo "All installations completed successfully."
echo "Kerno can be started up with $HOME/.kerno/assets/agent/$AGENT_RELEASE/startup.sh"
