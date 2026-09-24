#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

PROCESS_NAME="DeyeMacOS"

# Çalışan PID'leri bul
PIDS=$(pgrep -x "$PROCESS_NAME" 2>/dev/null || true)

if [ -z "$PIDS" ]; then
    echo -e "${BLUE}ℹ️  Çalışan herhangi bir $PROCESS_NAME süreci bulunamadı.${NC}"
    exit 0
fi

echo -e "${YELLOW}🛑 $PROCESS_NAME sonlandırılıyor (PID: $PIDS)...${NC}"

# Önce nazikçe kapat (SIGTERM)
kill $PIDS 2>/dev/null || true

# 3 saniye boyunca kapanmasını bekle
WAIT_SECONDS=3
TERMINATED=false

for ((i=0; i<WAIT_SECONDS*10; i++)); do
    if ! pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; then
        TERMINATED=true
        break
    fi
    sleep 0.1
done

# Kapanmadıysa zorla kapat (SIGKILL)
if [ "$TERMINATED" = false ]; then
    echo -e "${YELLOW}⚠️  Uygulama normal kapanmadı, zorla sonlandırılıyor (SIGKILL)...${NC}"
    killall -9 "$PROCESS_NAME" 2>/dev/null || true
    sleep 0.2
fi

if ! pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ $PROCESS_NAME başarıyla durduruldu.${NC}"
else
    echo -e "${RED}❌ $PROCESS_NAME durdurulamadı!${NC}"
    exit 1
fi
