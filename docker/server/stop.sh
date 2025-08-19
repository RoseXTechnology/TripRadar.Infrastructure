#!/bin/bash

set -e

echo "=========================================="
echo "   TripRadar Backend - Docker Shutdown"
echo "=========================================="
echo

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Locate docker-compose directory (supports sibling TripRadar.Server)
CANDIDATE1="$SCRIPT_DIR/../.."
CANDIDATE2="$SCRIPT_DIR/../../../TripRadar.Server"

if [[ -n "$TRIPRADAR_SERVER_DIR" && -f "$TRIPRADAR_SERVER_DIR/docker-compose.yml" ]]; then
    COMPOSE_DIR="$TRIPRADAR_SERVER_DIR"
elif [[ -f "$CANDIDATE1/docker-compose.yml" ]]; then
    COMPOSE_DIR="$CANDIDATE1"
elif [[ -f "$CANDIDATE2/docker-compose.yml" ]]; then
    COMPOSE_DIR="$CANDIDATE2"
else
    echo "[ERROR] Could not locate docker-compose.yml"
    echo "[INFO] Checked:"
    echo "  - $CANDIDATE1"
    echo "  - $CANDIDATE2"
    [[ -n "$TRIPRADAR_SERVER_DIR" ]] && echo "  - $TRIPRADAR_SERVER_DIR"
    echo "[HINT] Set TRIPRADAR_SERVER_DIR to your TripRadar.Server path."
    exit 1
fi

cd "$COMPOSE_DIR"

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Check if Docker is running
echo "[CHECK] Checking Docker status..."
if ! docker version >/dev/null 2>&1; then
    echo
    echo "[WARNING] Docker is not running."
    echo "[INFO] Nothing to stop."
    echo
    exit 0
fi

echo "[INFO] Docker is running."
echo

# Check if any TripRadar containers are running
echo "[CHECK] Looking for TripRadar containers..."
RUNNING_CONTAINERS=$(docker ps --filter "name=trip-radar" --format "{{.Names}}" 2>/dev/null | wc -l)

if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    echo "[INFO] No TripRadar containers are currently running."
    echo
    exit 0
fi

# Show running containers
echo "Current TripRadar containers:"
echo "------------------------------"
docker ps --filter "name=trip-radar" --format "table {{.Names}}\t{{.Status}}"
echo

# Stop containers
echo "[STOP] Stopping TripRadar services..."
if docker-compose -f docker-compose.yml -f docker-compose.override.yml down; then
    echo
    echo "=========================================="
    echo "   SUCCESS! TripRadar Backend Stopped"
    echo "=========================================="
    echo
    echo "All TripRadar services have been stopped."
    echo "Data volumes are preserved."
    echo
    echo "Quick Actions:"
    echo "--------------"
    echo "- Restart services: ./docker/server/start.sh"
    echo "- Clean all data:   ./docker/server/clean.sh"
    echo
    
    # Optional: Stop Docker
    read -r -t 10 -p "Do you want to stop Docker as well? (y/N): " STOP_DOCKER || true
    echo
    
    if [[ $STOP_DOCKER =~ ^[Yy]$ ]]; then
        echo "[DOCKER] Stopping Docker..."
        
        case $OS in
            macos)
                # macOS - quit Docker app
                osascript -e 'quit app "Docker"' 2>/dev/null || true
                sleep 2
                
                # Check if stopped
                if pgrep -x "Docker" > /dev/null; then
                    echo "[WARNING] Docker Desktop may still be running."
                    echo "[INFO] You can stop it manually from the menu bar."
                else
                    echo "[SUCCESS] Docker Desktop stopped."
                fi
                ;;
            linux)
                # Linux - stop Docker service
                if command -v systemctl &> /dev/null; then
                    if command -v sudo &> /dev/null; then
                        sudo systemctl stop docker 2>/dev/null || true
                        echo "[SUCCESS] Docker service stopped."
                    else
                        echo "[ERROR] sudo not available."
                        echo "[INFO] Stop Docker manually: sudo systemctl stop docker"
                    fi
                else
                    if command -v sudo &> /dev/null; then
                        sudo service docker stop 2>/dev/null || true
                        echo "[SUCCESS] Docker service stopped."
                    else
                        echo "[ERROR] sudo not available."
                        echo "[INFO] Stop Docker manually: sudo service docker stop"
                    fi
                fi
                ;;
            *)
                echo "[INFO] Please stop Docker manually."
                ;;
        esac
    else
        echo "[INFO] Docker will continue running."
    fi
else
    echo
    echo "[ERROR] Error stopping TripRadar Backend!"
    echo
    echo "Troubleshooting:"
    echo "- Try running: docker-compose down"
    echo "- Check for errors: docker-compose logs"
    echo
    exit 1
fi

echo 