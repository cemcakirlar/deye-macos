#!/usr/bin/env bash
set -euo pipefail

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
DO_BUILD=true
FOREGROUND=false

for arg in "$@"; do
    case "$arg" in
        --release|-r)
            CONFIG="Release"
            ;;
        --debug|-d)
            CONFIG="Debug"
            ;;
        --no-build|-n)
            DO_BUILD=false
            ;;
        --foreground|-f)
            FOREGROUND=true
            ;;
        --help|-h)
            echo "Kullanım: ./scripts/run.sh [SEÇENEKLER]"
            echo "  --debug, -d       : Debug modunda derler ve çalıştırır (Varsayılan)"
            echo "  --release, -r     : Release modunda derler ve çalıştırır"
            echo "  --foreground, -f  : Terminalde ön planda çalıştırır (canlı logları gösterir)"
            echo "  --no-build, -n    : Yeniden derlemeden mevcut ikiliyi çalıştırır"
            exit 0
            ;;
        *)
            echo -e "${RED}Bilinmeyen parametre: $arg${NC}"
            exit 1
            ;;
    esac
done

# 1. Varsa eski çalışan süreci durdur
"$SCRIPT_DIR/stop.sh"

# 2. Gerekirse derle
if [ "$DO_BUILD" = true ]; then
    if [ "$CONFIG" = "Release" ]; then
        "$SCRIPT_DIR/build.sh" --release
    else
        "$SCRIPT_DIR/build.sh" --debug
    fi
fi

APP_PATH="$PROJECT_ROOT/.build/DerivedData/Build/Products/$CONFIG/DeyeMacOS.app"
BINARY_PATH="$APP_PATH/Contents/MacOS/DeyeMacOS"

if [ ! -d "$APP_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}❌ Uygulama paketi bulunamadı: $APP_PATH${NC}"
    echo "Lütfen önce './scripts/build.sh' çalıştırın."
    exit 1
fi

if [ "$FOREGROUND" = true ]; then
    echo -e "${BLUE}🚀 DeyeMacOS terminal ön planında başlatılıyor (Ctrl+C ile durdurabilirsiniz)...${NC}"
    "$BINARY_PATH"
else
    echo -e "${BLUE}🚀 DeyeMacOS başlatılıyor...${NC}"
    open "$APP_PATH"
    
    # Başlamasını teyit et
    sleep 0.8
    NEW_PID=$(pgrep -x "DeyeMacOS" 2>/dev/null || true)
    if [ -n "$NEW_PID" ]; then
        echo -e "${GREEN}✅ DeyeMacOS aktif ve çalışıyor! (PID: $NEW_PID)${NC}"
        echo -e "   ℹ️  Menü çubuğundaki (Menu Bar) ikonunu kontrol edebilirsiniz."
    else
        echo -e "${YELLOW}⚠️  Uygulama açıldı fakat süreç PID'si hemen yakalanamadı. Menü çubuğunuzu kontrol edin.${NC}"
    fi
fi
