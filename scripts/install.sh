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

CONFIG="Release"
DEST_DIR="/Applications"
AUTO_LAUNCH=true

for arg in "$@"; do
    case "$arg" in
        --release|-r)
            CONFIG="Release"
            ;;
        --debug|-d)
            CONFIG="Debug"
            ;;
        --user|-u)
            DEST_DIR="$HOME/Applications"
            ;;
        --no-launch)
            AUTO_LAUNCH=false
            ;;
        --help|-h)
            echo "Kullanım: ./scripts/install.sh [SEÇENEKLER]"
            echo "  --release, -r  : Release (Prod) derleyip kurar (Varsayılan)"
            echo "  --debug, -d    : Debug derleyip kurar"
            echo "  --user, -u     : /Applications yerine ~/Applications dizinine kurar"
            echo "  --no-launch    : Kurulum sonrası uygulamayı otomatik başlatmaz"
            exit 0
            ;;
        *)
            echo -e "${RED}Bilinmeyen parametre: $arg${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}${BOLD}📦 Deye Solar Monitor Kurulum Sihirbazı${NC}"
echo -e "   Yapılandırma : ${BOLD}$CONFIG${NC}"
echo -e "   Hedef Dizin  : ${BOLD}$DEST_DIR${NC}"

# 1. Eski çalışan süreci durdur
"$SCRIPT_DIR/stop.sh"

# 2. Derle
if [ "$CONFIG" = "Release" ]; then
    "$SCRIPT_DIR/build.sh" --release
else
    "$SCRIPT_DIR/build.sh" --debug
fi

SOURCE_APP="$PROJECT_ROOT/.build/DerivedData/Build/Products/$CONFIG/DeyeMacOS.app"
TARGET_APP="$DEST_DIR/Deye Solar Monitor.app"

# Hedef dizin yoksa oluştur
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
fi

# /Applications yazma izin kontrolü
if [ ! -w "$DEST_DIR" ]; then
    echo -e "${YELLOW}⚠️  $DEST_DIR dizinine doğrudan yazma izni yok. Kullanıcı dizini ($HOME/Applications) deneniyor...${NC}"
    DEST_DIR="$HOME/Applications"
    mkdir -p "$DEST_DIR"
    TARGET_APP="$DEST_DIR/Deye Solar Monitor.app"
fi

# Varsa eski kurulu app'i kaldır
if [ -d "$TARGET_APP" ]; then
    echo -e "${YELLOW}🗑️  Eski sürüm kaldırılıyor: $TARGET_APP${NC}"
    rm -rf "$TARGET_APP"
fi

echo -e "${BLUE}📋 Uygulama kopyalanıyor...${NC}"
cp -R "$SOURCE_APP" "$TARGET_APP"
touch "$TARGET_APP"

# Ad-hoc imzalama ve Gatekeeper temizliği
echo -e "${BLUE}🔐 İzinler ve imza doğrulanıyor...${NC}"
codesign --force --deep --sign - "$TARGET_APP" > /dev/null 2>&1 || true
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true

# macOS LaunchServices kaydı yap (Spotlight & Launchpad'de hemen gözüksün)
if [ -x /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted "$TARGET_APP" > /dev/null 2>&1 || true
fi

echo -e "${GREEN}🎉 KURULUM BAŞARIYLA TAMAMLANDI!${NC}"
echo -e "   Konum: ${BOLD}$TARGET_APP${NC}"
echo -e "   • Artık Spotlight (Cmd + Space) veya Launchpad üzerinden '${BOLD}Deye Solar Monitor${NC}' yazarak açabilirsiniz."
echo -e "   • Mac açılışında otomatik başlamasını isterseniz: Sistem Ayarları -> Genel -> Giriş Öğeleri kısmına ekleyebilirsiniz."

if [ "$AUTO_LAUNCH" = true ]; then
    echo -e "\n${BLUE}🚀 Uygulama başlatılıyor...${NC}"
    open "$TARGET_APP"
    sleep 0.8
    NEW_PID=$(pgrep -x "DeyeMacOS" 2>/dev/null || true)
    if [ -n "$NEW_PID" ]; then
        echo -e "${GREEN}✅ Deye Solar Monitor menü çubuğunuzda aktif! (PID: $NEW_PID)${NC}"
    fi
fi
