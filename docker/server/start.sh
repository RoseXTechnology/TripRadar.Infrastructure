#!/bin/bash

set -e

echo "=========================================="
echo "    TripRadar Backend - Docker Startup"
echo "=========================================="
echo

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Navigate to the project root folder (2 levels up from docker/scripts)
cd "$SCRIPT_DIR/../.."

# === ADD THIS VERIFICATION BLOCK ===
echo "✅ Script is now running in the project root directory:"
pwd
echo "🧐 Checking for docker-compose.yml..."
ls -l docker-compose.yml
# ===================================
echo

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

# Check if Docker is installed
echo "[1/5] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo
    echo "[ERROR] Docker is not installed!"
    echo
    echo "Please install Docker Desktop from:"
    echo "https://www.docker.com/products/docker-desktop"
    echo
    exit 1
fi
echo "[SUCCESS] Docker command found!"
echo

# Check if Docker is running
echo "[2/5] Checking if Docker is running..."
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
    echo "[WAIT] Waiting for Docker to start (this may take 30-60 seconds)..."
    COUNTER=0
    while ! docker version >/dev/null 2>&1; do
        sleep 5
        COUNTER=$((COUNTER + 1))
        if [ $COUNTER -ge 12 ]; then
            echo
            echo "[ERROR] Docker failed to start after 60 seconds."
            echo "Please start Docker manually and try again."
            exit 1
        fi
        echo "[WAIT] Still waiting for Docker... ($((COUNTER * 5)) seconds)"
    done
fi
echo "[SUCCESS] Docker is running!"
echo

# Check docker-compose files
echo "[3/5] Checking docker-compose files..."
if [[ ! -f "docker-compose.yml" ]]; then
    echo "[ERROR] docker-compose.yml not found!"
    echo "Please ensure you're running this script from the TripRadar project folder."
    exit 1
fi
echo "[SUCCESS] Docker Compose files found!"
echo

# Check for .env file
echo "[4/5] Checking environment configuration..."
if [[ ! -f ".env" ]]; then
    echo "[WARNING] .env file not found!"
    echo
    echo "Please ensure you have a .env file in the project root directory."
    echo "You can use the .env.example file as a template if available."
    echo
    echo "The application may not work correctly without proper environment variables."
    echo
else
    echo "[SUCCESS] .env file found!"
fi
echo "[SUCCESS] Configuration ready!"
echo

# Start services
echo "[5/5] Starting TripRadar services..."
echo "This may take a few minutes on first run..."
if docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d --build; then
    echo
    echo "=========================================="
    echo "   SUCCESS! TripRadar Backend is Running"
    echo "=========================================="
    echo
    echo "Available Services:"
    echo "-------------------"
    echo "[API]       Main API:         http://localhost:5330"
    echo "[API]       Jobs API:         http://localhost:5382"
    echo "[DB]        PostgreSQL:       localhost:5432"
    echo "[CACHE]     Redis:            localhost:6379"
    echo "[MONITOR]   Grafana:          http://localhost:3000"
    echo "[LOGS]      Kibana:           http://localhost:5601"
    echo "[METRICS]   Prometheus:       http://localhost:9090"
    echo "[TRACE]     Jaeger:           http://localhost:16686"
    echo "[QUEUE]     Kafka UI:         http://localhost:8082"
    echo "[FLAGS]     Flagsmith:        http://localhost:8000"
    echo
    echo "Quick Actions:"
    echo "--------------"
    echo "- View logs:        docker-compose logs -f [service-name]"
    echo "- Stop services:    ./docker/scripts/stop.sh"
    echo "- Clean all data:   ./docker/scripts/clean.sh"
    echo
    echo "[TIP] Services may take 1-2 minutes to be fully ready."
    echo "[TIP] Check service health: docker-compose ps"
    echo
else
    echo
    echo "[ERROR] Failed to start TripRadar Backend!"
    echo
    echo "Troubleshooting:"
    echo "- Check if ports are already in use"
    echo "- View logs: docker-compose logs"
    echo "- Ensure Docker has enough resources allocated"
    echo
    exit 1
fi
