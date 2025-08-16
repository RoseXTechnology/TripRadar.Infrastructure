@echo off

echo ==========================================
echo    TripRadar Backend - Docker Startup
echo ==========================================
echo.

cd /d "%~dp0..\.."

echo [1/5] Checking Docker installation...
where docker >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Docker is not installed or not in PATH!
    echo.
    echo Please install Docker Desktop from:
    echo https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

echo [SUCCESS] Docker command found!
echo.

echo [2/5] Checking if Docker is running...
docker version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Docker is not running. Please start Docker Desktop manually.
    echo.
    echo After starting Docker Desktop, press any key to continue...
    pause
    
    echo [WAIT] Checking Docker again...
    docker version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Docker is still not running. Please start Docker Desktop first.
        pause
        exit /b 1
    )
)

echo [SUCCESS] Docker is running!
echo.

echo [3/5] Checking docker-compose files...
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found!
    echo Please ensure you're running this script from the TripRadar project folder.
    pause
    exit /b 1
)

if not exist "docker-compose.override.yml" (
    echo [WARNING] docker-compose.override.yml not found!
    echo The services may not start with the correct configuration.
)

echo [SUCCESS] Docker Compose files found!
echo.

echo [4/5] Checking environment configuration...
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo.
    echo Please ensure you have a .env file in the project root directory.
    echo You can use the .env.example file as a template if available.
    echo.
    echo The application may not work correctly without proper environment variables.
    echo.
) else (
    echo [SUCCESS] .env file found!
)

echo [SUCCESS] Configuration ready!
echo.

echo [5/5] Starting TripRadar services...
echo This may take a few minutes on first run...
echo.

docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d --build

if errorlevel 1 (
    echo.
    echo [ERROR] Failed to start TripRadar Backend!
    echo.
    echo Troubleshooting:
    echo - Check if ports are already in use
    echo - View logs: docker-compose logs
    echo - Ensure Docker has enough resources allocated
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo    SUCCESS! TripRadar Backend is Running
echo ==========================================
echo.
echo Available Services:
echo -------------------
echo [API]        Main API:        http://localhost:5330
echo [API]        Jobs API:        http://localhost:5382
echo [DB]         PostgreSQL:      localhost:5432
echo [CACHE]      Redis:           localhost:6379
echo [MONITOR]    Grafana:         http://localhost:3000
echo [LOGS]       Kibana:          http://localhost:5601
echo [METRICS]    Prometheus:      http://localhost:9090
echo [TRACE]      Jaeger:          http://localhost:16686
echo [QUEUE]      Kafka UI:        http://localhost:8082
echo [FLAGS]      Flagsmith:       http://localhost:8000
echo.
echo Quick Actions:
echo --------------
echo - View logs:       docker-compose logs -f [service-name]
echo - Stop services:   Run stop.bat
echo - Clean all data:  Run clean.bat
echo.
echo [TIP] Services may take 1-2 minutes to be fully ready.
echo [TIP] Check service health: docker-compose ps
echo.

pause