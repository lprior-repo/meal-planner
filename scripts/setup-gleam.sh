#!/usr/bin/env bash
# Gleam Toolchain Setup Script
# This script installs the Gleam compiler and its dependencies (Erlang/OTP)
#
# Requirements:
# - Ubuntu/Debian: apt package manager
# - macOS: Homebrew
# - Other: Manual installation from https://gleam.run
#
# Usage: ./scripts/setup-gleam.sh

set -euo pipefail

GLEAM_VERSION="${GLEAM_VERSION:-1.7.0}"
ERLANG_VERSION="${ERLANG_VERSION:-26}"

echo "=== Gleam Toolchain Setup ==="
echo "Gleam version: ${GLEAM_VERSION}"
echo "Erlang version: OTP ${ERLANG_VERSION}"
echo ""

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux";;
        Darwin*) echo "macos";;
        *)       echo "unknown";;
    esac
}

OS=$(detect_os)
echo "Detected OS: ${OS}"

# Check if commands exist
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Erlang
install_erlang() {
    echo ""
    echo "=== Installing Erlang/OTP ==="

    if command_exists erl; then
        echo "Erlang already installed: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'version check failed')"
        return 0
    fi

    case "${OS}" in
        linux)
            if command_exists apt-get; then
                echo "Installing via apt..."
                sudo apt-get update -qq
                sudo apt-get install -y -qq \
                    erlang-base \
                    erlang-dev \
                    erlang-crypto \
                    erlang-eunit \
                    erlang-dialyzer \
                    erlang-ssl \
                    erlang-inets \
                    erlang-parsetools
            else
                echo "ERROR: apt-get not found. Please install Erlang manually."
                echo "Visit: https://www.erlang.org/downloads"
                exit 1
            fi
            ;;
        macos)
            if command_exists brew; then
                echo "Installing via Homebrew..."
                brew install erlang
            else
                echo "ERROR: Homebrew not found. Please install Homebrew first:"
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            ;;
        *)
            echo "ERROR: Unsupported OS. Please install Erlang manually."
            exit 1
            ;;
    esac

    echo "Erlang installed successfully!"
}

# Install Gleam
install_gleam() {
    echo ""
    echo "=== Installing Gleam ==="

    if command_exists gleam; then
        INSTALLED_VERSION=$(gleam --version | awk '{print $2}')
        echo "Gleam already installed: v${INSTALLED_VERSION}"
        return 0
    fi

    case "${OS}" in
        linux)
            ARCH=$(uname -m)
            case "${ARCH}" in
                x86_64)  GLEAM_ARCH="x86_64-unknown-linux-musl";;
                aarch64) GLEAM_ARCH="aarch64-unknown-linux-musl";;
                *)       echo "ERROR: Unsupported architecture: ${ARCH}"; exit 1;;
            esac

            DOWNLOAD_URL="https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-${GLEAM_ARCH}.tar.gz"
            echo "Downloading from: ${DOWNLOAD_URL}"

            mkdir -p ~/.local/bin
            curl -fsSL "${DOWNLOAD_URL}" -o /tmp/gleam.tar.gz
            tar -xzf /tmp/gleam.tar.gz -C ~/.local/bin
            chmod +x ~/.local/bin/gleam
            rm /tmp/gleam.tar.gz

            # Add to PATH if not already
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo ""
                echo "Add this to your shell profile (~/.bashrc or ~/.zshrc):"
                echo '  export PATH="$HOME/.local/bin:$PATH"'
            fi
            ;;
        macos)
            if command_exists brew; then
                echo "Installing via Homebrew..."
                brew install gleam
            else
                # Fallback to direct download
                ARCH=$(uname -m)
                case "${ARCH}" in
                    x86_64)  GLEAM_ARCH="x86_64-apple-darwin";;
                    arm64)   GLEAM_ARCH="aarch64-apple-darwin";;
                    *)       echo "ERROR: Unsupported architecture: ${ARCH}"; exit 1;;
                esac

                DOWNLOAD_URL="https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-${GLEAM_ARCH}.tar.gz"
                echo "Downloading from: ${DOWNLOAD_URL}"

                mkdir -p ~/.local/bin
                curl -fsSL "${DOWNLOAD_URL}" -o /tmp/gleam.tar.gz
                tar -xzf /tmp/gleam.tar.gz -C ~/.local/bin
                chmod +x ~/.local/bin/gleam
                rm /tmp/gleam.tar.gz
            fi
            ;;
        *)
            echo "ERROR: Unsupported OS. Please install Gleam manually."
            echo "Visit: https://gleam.run/getting-started/installing/"
            exit 1
            ;;
    esac

    echo "Gleam installed successfully!"
}

# Verify installation
verify_installation() {
    echo ""
    echo "=== Verifying Installation ==="

    if command_exists erl; then
        echo "✓ Erlang: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'installed')"
    else
        echo "✗ Erlang: NOT FOUND"
        return 1
    fi

    if command_exists gleam; then
        echo "✓ Gleam:  $(gleam --version)"
    else
        echo "✗ Gleam:  NOT FOUND (check ~/.local/bin is in PATH)"
        return 1
    fi

    echo ""
    echo "=== Testing Gleam Build ==="
    cd "$(dirname "$0")/.."

    if gleam build 2>&1; then
        echo "✓ Build successful!"
    else
        echo "✗ Build failed"
        return 1
    fi

    echo ""
    echo "=== Setup Complete ==="
    echo "Run 'make test' or 'gleam test' to run the test suite."
}

# Main
install_erlang
install_gleam
verify_installation
