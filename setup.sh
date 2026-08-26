#!/usr/bin/env bash

# ==============================================================================
# Gitea Automated Local Build & Run Script
# Task 2: Environment checks, asset compilation, binary build, and startup
# ==============================================================================

set -e

# Color helpers for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}        Gitea Automated Setup & Launch Script       ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Verify running from correct project root directory
if [ ! -f "main.go" ] || [ ! -f "go.mod" ]; then
    echo -e "${RED}[ERROR] Please run this script from the Gitea root directory!${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Working directory verified: $(pwd)${NC}\n"

# 2. Check required dependencies and display versions
echo -e "${YELLOW}[CHECK] Checking required dependencies...${NC}"

check_tool() {
    local tool=$1
    local version_cmd=$2
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${RED}[ERROR] Required tool '$tool' is not installed or not in PATH.${NC}"
        exit 1
    else
        local ver=$($version_cmd 2>&1 | head -n 1)
        echo -e "${GREEN}  ✓ Found $tool: ${ver}${NC}"
    fi
}

check_tool "git" "git --version"
check_tool "go" "go version"
check_tool "node" "node --version"
check_tool "npm" "npm --version"

echo ""

# 3. Check if Port 3000 is already in use
echo -e "${YELLOW}[CHECK] Checking if port 3000 is free...${NC}"
if netstat -ano | grep -q ":3000.*LISTENING"; then
    echo -e "${RED}[ERROR] Port 3000 is already in use by another process!${NC}"
    echo -e "${YELLOW}Please terminate the existing process using port 3000 before proceeding.${NC}"
    exit 1
else
    echo -e "${GREEN}[OK] Port 3000 is available.${NC}\n"
fi

# 4. Install backend and frontend dependencies
echo -e "${YELLOW}[BUILD] Setting Go proxy and downloading modules...${NC}"
export GOPROXY="https://goproxy.io,direct"
go mod download
echo -e "${GREEN}[OK] Go modules downloaded successfully.${NC}\n"

echo -e "${YELLOW}[BUILD] Installing frontend dependencies...${NC}"
npm install --legacy-peer-deps --silent
echo -e "${GREEN}[OK] Frontend dependencies installed.${NC}\n"

# 5. Build frontend production assets
echo -e "${YELLOW}[BUILD] Building frontend assets with Vite...${NC}"
npx vite build
echo -e "${GREEN}[OK] Frontend assets compiled into public/ directory.${NC}\n"

# 6. Compile Gitea native binary
echo -e "${YELLOW}[BUILD] Compiling Gitea binary (pure Go mode)...${NC}"
CGO_ENABLED=0 go build -o gitea.exe .

# 7. Verify binary creation
if [ ! -f "gitea.exe" ]; then
    echo -e "${RED}[ERROR] Gitea binary (gitea.exe) was not generated!${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Gitea binary compiled successfully: gitea.exe${NC}\n"

# 8. Start Gitea Web Server
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}  Gitea is starting up!${NC}"
echo -e "${GREEN}  Access URL: ${BLUE}http://localhost:3000${NC}"
echo -e "${YELLOW}  Press Ctrl+C to stop the server at any time.${NC}"
echo -e "${BLUE}====================================================${NC}\n"

./gitea.exe web
