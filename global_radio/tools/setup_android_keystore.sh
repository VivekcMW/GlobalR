#!/bin/bash
# Android Keystore Setup Script for Global Radio
# This script helps create and configure the release keystore for signing the app.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN} Global Radio - Android Keystore Setup${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Navigate to android directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR/../android"
KEYSTORE_DIR="$SCRIPT_DIR/../keystore"

# Create keystore directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

KEYSTORE_FILE="$KEYSTORE_DIR/release.keystore"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo -e "${YELLOW}Warning: Keystore already exists at $KEYSTORE_FILE${NC}"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing keystore."
        exit 0
    fi
fi

echo -e "${YELLOW}Creating new release keystore...${NC}"
echo ""
echo "You will be prompted for:"
echo "  1. Keystore password (remember this!)"
echo "  2. Key password (can be same as keystore password)"
echo "  3. Your name and organization details"
echo ""

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -alias global_radio \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storetype JKS

echo ""
echo -e "${GREEN}Keystore created successfully!${NC}"
echo ""

# Prompt for passwords to create key.properties
echo -e "${YELLOW}Now let's create key.properties...${NC}"
echo ""

read -sp "Enter the keystore password you just created: " STORE_PASSWORD
echo ""
read -sp "Enter the key password (or press Enter if same as keystore): " KEY_PASSWORD
echo ""

# Use keystore password if key password not specified
if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$STORE_PASSWORD"
fi

# Create key.properties
cat > "$KEY_PROPERTIES" << EOF
# Key store configuration for release builds.
# DO NOT commit this file to version control - it contains sensitive data.

storeFile=../keystore/release.keystore
storePassword=$STORE_PASSWORD
keyAlias=global_radio
keyPassword=$KEY_PASSWORD
EOF

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN} Setup Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo "Created files:"
echo "  ✅ $KEYSTORE_FILE"
echo "  ✅ $KEY_PROPERTIES"
echo ""
echo -e "${YELLOW}IMPORTANT: Back up your keystore file and passwords!${NC}"
echo "If you lose them, you won't be able to update your app on Play Store."
echo ""
echo "Recommended backup locations:"
echo "  - Password manager (1Password, Bitwarden, etc.)"
echo "  - Encrypted cloud storage"
echo "  - Secure offline backup"
echo ""
echo -e "${GREEN}You can now build a release APK/AAB with:${NC}"
echo "  flutter build apk --release"
echo "  flutter build appbundle --release"
