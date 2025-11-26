#!/bin/bash

required_tools=("curl" "grep" "sed" "awk")
for tool in "${required_tools[@]}"; do
  command -v "$tool" > /dev/null 2>&1 || { echo "Error: '$tool' is required but not installed"; exit 1; }
done

# BEGIN - AUTO GENERATED DO NOT EDIT
RUNTIME_RELEASE=2025.11.14.14
AGENT_RELEASE=2025.11.26
AGENT_ASSET_ID=321068979
RUNTIME_ASSET_ID_LINUX_X64=316427994
RUNTIME_ASSET_ID_LINUX_AARCH64=316427992
RUNTIME_ASSET_ID_DARWIN_X64=316427995
RUNTIME_ASSET_ID_DARWIN_AARCH64=316427996
RUNTIME_ASSET_ID_WINDOWS_AMD64=316427993
# END - AUTO GENERATED DO NOT EDIT

# Override with latest dev pre-release assets if DEV=true
if [ "${DEV:-false}" == "true" ]; then
  # Fetch latest-dev pre-release to get release ID
  RELEASE_INFO=$(curl -s \
    "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/tags/latest-dev")

  if echo "$RELEASE_INFO" | grep -q '"message"'; then
    echo "Error: Could not fetch latest-dev release. Check ensure latest-dev pre-release exists"
    exit 1
  fi

  # Extract release ID and tag name
  RELEASE_ID=$(echo "$RELEASE_INFO" | grep -o '"id": [0-9]*' | head -1 | grep -o '[0-9]*$')
  AGENT_RELEASE=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | head -1 | sed 's/"tag_name": "\([^"]*\)"/\1/')

  # Fetch assets for this release using the release ID
  ASSETS_DATA=$(curl -s \
    "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/$RELEASE_ID/assets")

  if echo "$ASSETS_DATA" | grep -q '"message"'; then
    echo "Error: Could not fetch assets."
    exit 1
  fi

  # Simpler approach: search for filename, then extract the id from the same object
  AGENT_ASSET_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "kerno-agent.tar.gz"' | grep '"id":' | grep -o '[0-9]*' | head -1)
  LINUX_X64_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "custom-jre-linux-x64.tar.gz"' | grep '"id":' | grep -o '[0-9]*' | head -1)
  LINUX_AARCH64_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "custom-jre-linux-aarch64.tar.gz"' | grep '"id":' | grep -o '[0-9]*' | head -1)
  DARWIN_X64_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "custom-jre-darwin-x64.tar.gz"' | grep '"id":' | grep -o '[0-9]*' | head -1)
  DARWIN_AARCH64_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "custom-jre-darwin-aarch64.tar.gz"' | grep '"id":' | grep -o '[0-9]*' | head -1)
  WINDOWS_AMD64_ID=$(echo "$ASSETS_DATA" | grep -B 5 '"name": "custom-jre-windows-amd64.zip"' | grep '"id":' | grep -o '[0-9]*' | head -1)

  # Override if assets exist
  [ -n "$AGENT_ASSET_ID" ] && AGENT_ASSET_ID="$AGENT_ASSET_ID"
  [ -n "$LINUX_X64_ID" ] && RUNTIME_ASSET_ID_LINUX_X64="$LINUX_X64_ID"
  [ -n "$LINUX_AARCH64_ID" ] && RUNTIME_ASSET_ID_LINUX_AARCH64="$LINUX_AARCH64_ID"
  [ -n "$DARWIN_X64_ID" ] && RUNTIME_ASSET_ID_DARWIN_X64="$DARWIN_X64_ID"
  [ -n "$DARWIN_AARCH64_ID" ] && RUNTIME_ASSET_ID_DARWIN_AARCH64="$DARWIN_AARCH64_ID"
  [ -n "$WINDOWS_AMD64_ID" ] && RUNTIME_ASSET_ID_WINDOWS_AMD64="$WINDOWS_AMD64_ID"

  # Update RUNTIME_RELEASE if any runtime assets exist
  if [ -n "$LINUX_X64_ID" ] || [ -n "$LINUX_AARCH64_ID" ] || [ -n "$DARWIN_X64_ID" ] || [ -n "$DARWIN_AARCH64_ID" ] || [ -n "$WINDOWS_AMD64_ID" ]; then
    RUNTIME_RELEASE="$AGENT_RELEASE"
  fi

  echo "Clearing out old latest-dev builds"

  rm -rf $HOME/.kerno/assets/agent/latest-dev
  rm -rf $HOME/.kerno/assets/runtime/latest-dev

  echo "Using latest-dev pre-release assets (AGENT_RELEASE=$AGENT_RELEASE)"
fi

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

RUNTIME_FINISHED_FILE="$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/finished"
if [ -f "$RUNTIME_FINISHED_FILE" ]; then
    echo "Runtime $RUNTIME_RELEASE already installed, skipping download."
else
    echo "Downloading runtime $RUNTIME_RELEASE..."

    # Create directories
    mkdir -p "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"
    mkdir -p "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"
    curl -L \
        -H "Accept: application/octet-stream" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -o "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz" \
        "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$RUNTIME_ASSET_ID"

    if [ $? -eq 0 ]; then
        echo "Extracting runtime..."
        tar -xzf "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz" -C "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE"
        if [ $? -eq 0 ]; then
            rm "$HOME/.kerno/assets/runtime/$RUNTIME_RELEASE/runtime.tar.gz"
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

AGENT_FINISHED_FILE="$HOME/.kerno/assets/agent/$AGENT_RELEASE/finished"

if [ -f "$AGENT_FINISHED_FILE" ]; then
    echo "Agent $AGENT_RELEASE already installed, skipping download."
else
    echo "Downloading agent $AGENT_RELEASE..."
    mkdir -p "$HOME/.kerno/assets/agent/$AGENT_RELEASE"
    curl -L \
        -H "Accept: application/octet-stream" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -o "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz" \
        "https://api.github.com/repos/kernoio/kerno-agent-runtimes/releases/assets/$AGENT_ASSET_ID"

    if [ $? -eq 0 ]; then
        echo "Extracting agent..."
        tar -xzf "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz" -C "$HOME/.kerno/assets/agent/$AGENT_RELEASE"

        if [ $? -eq 0 ]; then
            rm "$HOME/.kerno/assets/agent/$AGENT_RELEASE/agent.tar.gz"
            touch "$AGENT_FINISHED_FILE"
            STARTUP_SCRIPT="$HOME/.kerno/assets/agent/$AGENT_RELEASE/startup.sh"
            cat > "$STARTUP_SCRIPT" << 'EOF'
            #!/bin/bash

            export JAVA_HOME=$HOME/.kerno/assets/runtime/RUNTIME_VERSION_PLACEHOLDER/custom-jre
            "$HOME"/.kerno/assets/agent/AGENT_VERSION_PLACEHOLDER/aicore-agent/bin/aicore-agent
EOF
            sed -i.bak "s|AGENT_VERSION_PLACEHOLDER|$AGENT_RELEASE|g" "$STARTUP_SCRIPT"
            sed -i.bak "s|RUNTIME_VERSION_PLACEHOLDER|$RUNTIME_RELEASE|g" "$STARTUP_SCRIPT"
            rm "${STARTUP_SCRIPT}.bak"
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
