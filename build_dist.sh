#!/bin/bash
set -e

# Configuration
APP_NAME="JugaBar"
VERSION="${VERSION:-1.0.0}"
ZIP_NAME="${APP_NAME}-v${VERSION}.zip"

echo "🚀 Building ${APP_NAME}..."

# 1. Build
swift build -c release

# 2. Bundle
echo "📦 Bundling..."
rm -rf ${APP_NAME}.app
mkdir -p ${APP_NAME}.app/Contents/MacOS
mkdir -p ${APP_NAME}.app/Contents/Resources
cp .build/release/${APP_NAME} ${APP_NAME}.app/Contents/MacOS/
cp Info.plist ${APP_NAME}.app/Contents/
if [ -f "JugaBar.icns" ]; then
    cp JugaBar.icns ${APP_NAME}.app/Contents/Resources/JugaIcon.icns
fi

# 3. Zip
echo "🤐 Zipping..."
rm -f ${ZIP_NAME}
zip -r ${ZIP_NAME} ${APP_NAME}.app

# 4. Checksum
echo "✅ SHA256 Checksum:"
shasum -a 256 ${ZIP_NAME}

echo "🎉 Done! Upload '${ZIP_NAME}' to your GitHub Releases."