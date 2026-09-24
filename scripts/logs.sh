#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}📋 DeyeMacOS canlı sistem logları dinleniyor (Ctrl+C ile çıkabilirsiniz)...${NC}"
log stream --predicate 'process == "DeyeMacOS" || senderImagePath CONTAINS[c] "DeyeMacOS"' --level debug --style compact
