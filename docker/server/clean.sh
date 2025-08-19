#!/bin/bash

set -e

echo "=========================================="
echo "   TripRadar Backend - Clean All Data"
echo "=========================================="
echo
echo "    !!!! DANGER ZONE !!!!"
echo
echo "This operation will DELETE (TripRadar only):"
echo "   [X] TripRadar containers (from docker-compose)"
echo "   [X] TripRadar volumes (data will be lost)"
echo "   [X] Database data stored in TripRadar volumes"
echo "   [X] Redis cache stored in TripRadar volumes"
echo "   [X] Logs and metrics kept in TripRadar volumes"
echo "   [X] Uploaded files kept in TripRadar volumes"
echo
echo "Optional: You can also remove ALL unused Docker data (images, containers, networks, volumes) across your machine."
echo
echo "This action is IRREVERSIBLE!"
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

# Double confirmation for safety
read -p "Are you ABSOLUTELY SURE you want to delete ALL data? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo
    echo "[CANCEL] Clean operation cancelled."
    echo "[INFO] Your data is safe."
    exit 0
fi

echo
read -p "Type 'DELETE ALL' to confirm: " CONFIRM_TEXT
if [[ "$CONFIRM_TEXT" != "DELETE ALL" ]]; then
    echo
    echo "[CANCEL] Clean operation cancelled."
    echo "[INFO] You must type 'DELETE ALL' to proceed."
    exit 0
fi

echo
echo "[START] Beginning cleanup process..."
echo

# Check if Docker is running
echo "[1/4] Checking Docker status..."
if ! docker version >/dev/null 2>&1; then
    echo "[WARNING] Docker is not running. Attempting to start Docker..."
    
    case $OS in
        macos)
            open -a Docker
            echo "[WAIT] Starting Docker Desktop for macOS..."
            ;;
        linux)
            if command -v systemctl &> /dev/null; then
                sudo systemctl start docker 2>/dev/null || true
                echo "[WAIT] Starting Docker service..."
            else
                sudo service docker start 2>/dev/null || true
                echo "[WAIT] Starting Docker service..."
            fi
            ;;
        *)
            echo "[ERROR] Please start Docker manually and run this script again."
            exit 1
            ;;
    esac
    
    # Wait for Docker to be ready
    echo "[WAIT] Waiting for Docker to start (up to 60 seconds)..."
    COUNTER=0
    while ! docker version >/dev/null 2>&1; do
        sleep 5
        COUNTER=$((COUNTER + 1))
        if [ $COUNTER -ge 12 ]; then
            echo
            echo "[ERROR] Docker failed to start."
            echo "[INFO] Please start Docker manually and try again."
            exit 1
        fi
        echo "[WAIT] Still waiting for Docker... ($((COUNTER * 5)) seconds)"
    done
fi

echo "[SUCCESS] Docker is running."
echo

# List what will be deleted
echo "[2/4] Analyzing TripRadar resources..."
echo
echo "Containers to be removed:"
echo "-------------------------"
CONTAINERS=$(docker ps -a --filter "name=trip-radar" --format "- {{.Names}}" 2>/dev/null)
if [ -z "$CONTAINERS" ]; then
    echo "- None found"
else
    echo "$CONTAINERS"
fi
echo

echo "Volumes to be removed:"
echo "----------------------"
VOLUMES=$(docker volume ls --filter "name=trip-radar" --format "- {{.Name}}" 2>/dev/null)
if [ -z "$VOLUMES" ]; then
    echo "- None found"
else
    echo "$VOLUMES"
fi
echo

# Stop and remove containers with volumes
echo "[3/4] Removing TripRadar containers and volumes..."
docker-compose -f docker-compose.yml -f docker-compose.override.yml down -v --remove-orphans --timeout 30 2>/dev/null || true

# Force remove any remaining containers
if [ -n "$(docker ps -aq --filter 'name=trip-radar' 2>/dev/null)" ]; then
    echo "[INFO] Force removing remaining containers..."
    docker ps -aq --filter "name=trip-radar" | xargs -r docker rm -f 2>/dev/null || true
fi

# Force remove any remaining volumes
if [ -n "$(docker volume ls -q --filter 'name=trip-radar' 2>/dev/null)" ]; then
    echo "[INFO] Force removing remaining volumes..."
    docker volume ls -q --filter "name=trip-radar" | xargs -r docker volume rm -f 2>/dev/null || true
fi

# Optional: Clean up Docker system (GLOBAL)
echo
read -t 10 -p "Do you also want to remove ALL unused Docker data (global prune)? (y/N): " PRUNE_ALL || true
echo
echo "[4/4] Cleaning Docker system..."
if [[ $PRUNE_ALL =~ ^[Yy]$ ]]; then
    docker system prune -af --volumes 2>/dev/null || true
    PRUNE_MSG="[OK] Docker system globally pruned"
else
    echo "[SKIP] Global Docker prune skipped."
    PRUNE_MSG="[SKIP] Global prune skipped"
fi

# Remove .env file if requested
echo
read -t 10 -p "Do you also want to remove the .env configuration file? (y/N): " REMOVE_ENV || true
echo

if [[ $REMOVE_ENV =~ ^[Yy]$ ]]; then
    if [ -f ".env" ]; then
        rm -f ".env"
        echo "[INFO] .env file removed."
    fi
fi

# Final status
echo
echo "=========================================="
echo "   CLEANUP COMPLETE!"
echo "=========================================="
echo
echo "Summary:"
echo "---------"
echo "[OK] All TripRadar containers removed"
echo "[OK] All TripRadar volumes removed"
echo "[OK] All cached data cleared"
echo "$PRUNE_MSG"
echo
echo "Next Steps:"
echo "-----------"
echo "1. Run ./docker/server/start.sh to create fresh containers"
echo "2. Update .env file with your API keys"
echo "3. Services will initialize with clean data"
echo