#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Caesium Image Compressor Linux AppImage builder
# Repository: https://github.com/<your-username>/caesium-image-compressor
set -euo pipefail

BUILD_DIR=/tmp/build
SRC_DIR=/tmp/src
APPDIR=/AppDir

echo "=== [1/6] Clone source v2.8.5 ==="
git clone --depth 1 --branch v2.8.5 \
    https://github.com/Lymphatus/caesium-image-compressor.git "$SRC_DIR"

cd "$SRC_DIR"

echo "=== [2/6] CMake Configure ==="

# Auto-detect Qt6 path if QT6_DIR is not set or doesn't exist
if [ -z "${QT6_DIR:-}" ] || [ ! -f "$QT6_DIR/lib/cmake/Qt6/Qt6Config.cmake" ]; then
    echo "QT6_DIR(${QT6_DIR:-unset}) not found, auto-detecting..."
    FOUND=$(find / -name "Qt6Config.cmake" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        QT6_DIR=${FOUND%/lib/cmake/Qt6/Qt6Config.cmake}
        echo "Found Qt6 at: $QT6_DIR"
    else
        echo "ERROR: Qt6Config.cmake not found anywhere!"
        echo "--- Searching /opt/Qt ---"
        find /opt/Qt -maxdepth 3 -type d 2>/dev/null || echo "(no /opt/Qt directory)"
        echo "--- Searching /root/Qt ---"
        find /root/Qt -maxdepth 3 -type d 2>/dev/null || echo "(no /root/Qt directory)"
        echo "--- Full search ---"
        find / -name "Qt6Config.cmake" -type f 2>/dev/null || echo "(not found)"
        exit 1
    fi
fi

echo "Using QT6_DIR=$QT6_DIR"
cmake -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${QT6_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${APPDIR}/usr"

echo "=== [3/6] Compile ==="
cmake --build "$BUILD_DIR" --config Release --target caesium_image_compressor -j"$(nproc)"

echo "=== [4/6] Install to AppDir ==="
cmake --install "$BUILD_DIR" --prefix "${APPDIR}/usr"

echo "=== [5/6] Create AppImage metadata ==="

cat > "$APPDIR/caesium-image-compressor.desktop" << 'EOF'
[Desktop Entry]
Name=Caesium Image Compressor
Comment=Image compression software
Exec=caesium-image-compressor
Icon=caesium-image-compressor
Categories=Graphics;Photography;
Type=Application
Terminal=false
EOF

cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/plugins"
exec "${HERE}/usr/bin/caesium-image-compressor" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

cp "$SRC_DIR/resources/icons/logo.png" "$APPDIR/caesium-image-compressor.png"

echo "=== [6/6] Package AppImage ==="
export QMAKE="${QT6_DIR}/bin/qmake"
export LD_LIBRARY_PATH="${QT6_DIR}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

cd /tmp
linuxdeploy \
    --appdir "$APPDIR" \
    --plugin qt \
    --output appimage

cp /tmp/Caesium_Image_Compressor-*.AppImage /output/ 2>/dev/null || true

echo "=== Done ==="
ls -lh /output/ 2>/dev/null || true
