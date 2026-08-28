#!/usr/bin/env bash
# =============================================================================
# setup.sh — Full developer environment setup for this project.
#
# Run via:  npm run setup
#
# What this does:
#   1. Installs Java 17 (required for Android/Gradle builds)
#   2. Downloads and installs Android SDK command-line tools (no Android Studio needed)
#   3. Installs required Android SDK components via sdkmanager
#   4. Writes ANDROID_HOME and PATH to your shell profile
#   5. Validates KVM for emulator hardware acceleration (Linux only)
#
# Prerequisites:
#   - Node.js 20+  →  install via nvm: https://github.com/nvm-sh/nvm
# =============================================================================
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BOLD}→ $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
error()   { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ─── 1. Java 17 ───────────────────────────────────────────────────────────────
info "Checking Java 17..."
if java -version 2>&1 | grep -q 'version "17'; then
  success "Java 17 already installed"
else
  info "Installing Java 17..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y openjdk-17-jdk
  elif command -v brew &>/dev/null; then
    brew install openjdk@17
    sudo ln -sfn "$(brew --prefix openjdk@17)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || true
  else
    error "Cannot install Java automatically. Please install JDK 17 manually."
  fi
  success "Java 17 installed"
fi

# ─── 2. Android SDK command-line tools ────────────────────────────────────────
info "Setting up Android SDK at $ANDROID_HOME ..."
mkdir -p "$ANDROID_HOME/cmdline-tools"

if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  success "Android cmdline-tools already present"
else
  info "Downloading Android command-line tools (~150MB)..."
  TMP_ZIP="/tmp/cmdline-tools.zip"
  curl -fsSL "$CMDLINE_TOOLS_URL" -o "$TMP_ZIP"
  unzip -q "$TMP_ZIP" -d "/tmp/cmdline-tools-extracted"
  mv "/tmp/cmdline-tools-extracted/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$TMP_ZIP" "/tmp/cmdline-tools-extracted"
  success "Android command-line tools installed"
fi

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

# ─── 3. Accept licenses and install SDK components ────────────────────────────
info "Accepting Android SDK licenses..."
yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 || true

info "Installing Android SDK components (platform-tools, build-tools, Android 35)..."
"$SDKMANAGER" \
  "platform-tools" \
  "build-tools;35.0.0" \
  "platforms;android-35"
success "Android SDK components installed"

# ─── 4. Write environment variables to shell profile ─────────────────────────
info "Configuring environment variables..."

MARKER="# BEGIN rail-seek android sdk"
EXPORT_BLOCK="$MARKER
export ANDROID_HOME=\"$ANDROID_HOME\"
export ANDROID_AVD_HOME=\"\${XDG_CONFIG_HOME:-\$HOME}/.android/avd\"
export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator\"
# END rail-seek android sdk"

add_to_profile() {
  local profile="$1"
  [ -f "$profile" ] || return 0
  if grep -q "BEGIN rail-seek android sdk" "$profile"; then
    warn "Android SDK env already in $profile — skipping"
  else
    echo "" >> "$profile"
    echo "$EXPORT_BLOCK" >> "$profile"
    success "Added Android SDK env to $profile"
  fi
}

add_to_profile "$HOME/.bashrc"
add_to_profile "$HOME/.zshrc"
add_to_profile "$HOME/.profile"

export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_AVD_HOME="${XDG_CONFIG_HOME:-$HOME}/.android/avd"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# ─── 5. KVM validation (Linux emulator hardware acceleration) ─────────────────
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  info "Validating KVM for Android emulator hardware acceleration..."
  VT_FLAGS=$(grep -Ec '(vmx|svm)' /proc/cpuinfo 2>/dev/null || echo 0)
  if [ "$VT_FLAGS" -eq 0 ]; then
    warn "CPU does not report VT-x/AMD-V flags."
    warn "Hardware virtualisation must be enabled in BIOS/UEFI."
  else
    success "CPU supports hardware virtualisation (VT-x/AMD-V)"
    if ! lsmod | grep -q '^kvm '; then
      info "Loading KVM kernel module..."
      if grep -q 'vmx' /proc/cpuinfo; then
        sudo modprobe kvm_intel 2>/dev/null || true
      else
        sudo modprobe kvm_amd 2>/dev/null || true
      fi
    fi
    if [ ! -e /dev/kvm ]; then
      info "Installing qemu-kvm..."
      sudo apt-get install -y qemu-kvm
    fi
    if [ -e /dev/kvm ]; then
      success "KVM available — emulator will run at full speed"
      if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        success "KVM permissions OK"
      else
        info "Granting KVM access to user '$USER'..."
        sudo usermod -aG kvm "$USER"
        warn "Log out and back in for group membership to take effect."
      fi
    else
      warn "KVM device still not available. VT-x/AMD-V may be disabled in BIOS."
    fi
  fi
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}✅ Setup complete!${NC}"
echo ""
echo "⚠️  Restart your terminal (or run: source ~/.bashrc) to activate ANDROID_HOME."
echo ""
echo "Next steps:"
echo "  ./gradlew assembleDebug     — Build the debug APK"
echo "  npm run check               — Compile and lint"
echo ""
