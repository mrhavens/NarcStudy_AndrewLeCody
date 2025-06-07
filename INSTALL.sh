#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ╭─────────────────────────────────────╮
# │          CONFIGURATION              │
# ╰─────────────────────────────────────╮
REPO_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || { echo -e "\e[1;31m[ERROR]\e[0m Not inside a Git repository" >&2; exit 1; }
BIN_DIR="$REPO_PATH/bin"
INSTALL_DIR="$HOME/.local/gitfieldbin"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SCRIPT_VERSION="1.0"

# ╭─────────────────────────────────────╮
# │           LOGGING UTILS             │
# ╰─────────────────────────────────────╮
info()  { echo -e "\e[1;34m[INFO]\e[0m $*" >&2; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*" >&2; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

# ╭─────────────────────────────────────╮
# │         DETECT SHELL CONFIG         │
# ╰─────────────────────────────────────╮
detect_shell_config() {
    local shell_name=$(basename "$SHELL")
    case "$shell_name" in
        bash)
            if [[ -f "$HOME/.bash_profile" && "$(uname)" == "Darwin" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        *)
            warn "Unsupported shell: $shell_name. Defaulting to ~/.bashrc"
            echo "$HOME/.bashrc"
            ;;
    esac
}

# ╭─────────────────────────────────────╮
# │         UPDATE PATH FUNCTION        │
# ╰─────────────────────────────────────╮
update_path() {
    local config_file=$1
    local path_entry="export PATH=\$PATH:$INSTALL_DIR"

    # Check for duplicate PATH entries in the config file
    if [[ -f "$config_file" ]]; then
        # Remove any existing entries for INSTALL_DIR using a different delimiter
        sed -i.bak "\|export PATH=.*$INSTALL_DIR|d" "$config_file" && rm -f "$config_file.bak"
        info "Removed any existing $INSTALL_DIR entries from $config_file"
    fi

    # Check if PATH already contains $INSTALL_DIR in the current session
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        info "$INSTALL_DIR is already in PATH for the current session"
    else
        info "Adding $INSTALL_DIR to PATH in current session"
        export PATH="$PATH:$INSTALL_DIR"
    fi

    # Add new PATH entry to config file
    info "Adding $INSTALL_DIR to $config_file"
    echo "" >> "$config_file"
    echo "# Added by git-sigil INSTALL.sh at $TIMESTAMP" >> "$config_file"
    echo "$path_entry" >> "$config_file"
}

# ╭─────────────────────────────────────╮
# │         INSTALL SCRIPTS             │
# ╰─────────────────────────────────────╮
install_scripts() {
    info "Installing scripts from $BIN_DIR to $INSTALL_DIR..."

    # Create installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR" || error "Failed to create $INSTALL_DIR"

    # Check if bin directory exists and contains scripts
    if [[ ! -d "$BIN_DIR" ]]; then
        error "Directory $BIN_DIR does not exist"
    fi

    # Copy all executable files from BIN_DIR to INSTALL_DIR
    local found_scripts=false
    for script in "$BIN_DIR"/*; do
        if [[ -f "$script" && -x "$script" ]]; then
            found_scripts=true
            local script_name=$(basename "$script")
            info "Installing $script_name to $INSTALL_DIR..."
            cp -f "$script" "$INSTALL_DIR/" || error "Failed to install $script_name"
            chmod +x "$INSTALL_DIR/$script_name" || error "Failed to set executable permissions for $script_name"
        fi
    done

    if [[ "$found_scripts" == false ]]; then
        warn "No executable scripts found in $BIN_DIR"
    fi

    # Verify and fix permissions for all installed scripts
    info "Verifying executable permissions in $INSTALL_DIR..."
    for script in "$INSTALL_DIR"/*; do
        if [[ -f "$script" && ! -x "$script" ]]; then
            warn "Script $script is not executable, fixing permissions..."
            chmod +x "$script" || error "Failed to set executable permissions for $script"
        fi
    done
}

# ╭─────────────────────────────────────╮
# │            MAIN EXECUTION           │
# ╰─────────────────────────────────────╮
info "Starting git-sigil installation at $TIMESTAMP..."

# Install scripts
install_scripts

# Detect shell configuration file
CONFIG_FILE=$(detect_shell_config)
info "Detected shell configuration file: $CONFIG_FILE"

# Create config file if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "$CONFIG_FILE does not exist, creating it..."
    touch "$CONFIG_FILE" || error "Failed to create $CONFIG_FILE"
fi

# Update PATH in configuration file and current session
update_path "$CONFIG_FILE"

# Source the configuration file to update the current session
info "Sourcing $CONFIG_FILE to update current session..."
# shellcheck disable=SC1090
source "$CONFIG_FILE" || warn "Failed to source $CONFIG_FILE, but PATH will be updated on next login"

info "✅ Installation completed successfully."
info "🔗 Scripts installed to: $INSTALL_DIR"
info "🔗 PATH updated in: $CONFIG_FILE"
info "🔗 You can now run the installed scripts (e.g., gitfield-sync) from anywhere."
