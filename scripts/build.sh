#!/usr/bin/env bash
set -euo pipefail

# Renkler ve emojiler
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

CONFIG="Debug"
DO_CLEAN=false

for arg in "$@"; do
    case "$arg" in
        --release|--Release|-r)
            CONFIG="Release"
            ;;
        --debug|--Debug|-d)
            CONFIG="Debug"
            ;;
        --clean|-c)
            DO_CLEAN=true
            ;;
        --help|-h)
            echo "Kullanım: ./scripts/build.sh [--debug | --release] [--clean]"
            echo "  --debug, -d   : Debug modunda derler (Varsayılan)"
            echo "  --release, -r : Release (Prod) modunda derler"
            echo "  --clean, -c   : Derleme öncesi önbelleği temizler"
            exit 0
            ;;
        *)
            echo -e "${RED}Bilinmeyen parametre: $arg${NC}"
            exit 1
            ;;
    esac
done

DERIVED_DATA_DIR="$PROJECT_ROOT/.build/DerivedData"

if [ "$DO_CLEAN" = true ]; then
    echo -e "${YELLOW}🧹 Derleme önbelleği temizleniyor...${NC}"
    rm -rf "$DERIVED_DATA_DIR"
fi

echo -e "${BLUE}${BOLD}🔨 DeyeMacOS derleniyor... [Mod: $CONFIG]${NC}"
START_TIME=$(date +%s)

xcodebuild \
    -project DeyeMacOS.xcodeproj \
    -scheme DeyeMacOS \
    -destination 'platform=macOS' \
    -configuration "$CONFIG" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build \
    CODE_SIGNING_ALLOWED=NO \
    -quiet 2>&1 | grep -v -E "IDEDownloadableMetalToolchainCoordinator|IDESimulatorRuntimeVersionCoordinator|Operation not permitted|Supported platforms for the buildables|matching destinations" || true

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIG/DeyeMacOS.app"

if [ -d "$APP_PATH" ]; then
    # Yerel çalıştırma için ad-hoc kod imzalama
    codesign --force --deep --sign - "$APP_PATH" > /dev/null 2>&1 || true

    echo -e "${GREEN}✅ Derleme başarıyla tamamlandı! (${DURATION}s)${NC}"
    echo -e "   📦 Konum: ${BOLD}$APP_PATH${NC}"
else
    echo -e "${RED}❌ Derleme tamamlandı fakat $APP_PATH bulunamadı!${NC}"
    exit 1
fi
