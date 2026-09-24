#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}📋 Streaming live DeyeMacOS logs (Press Ctrl+C to exit)...${NC}"
log stream --predicate 'process == "DeyeMacOS" || senderImagePath CONTAINS[c] "DeyeMacOS"' --level debug --style compact
