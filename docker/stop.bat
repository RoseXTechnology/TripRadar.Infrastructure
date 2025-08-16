@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo    TripRadar Backend - Docker Shutdown
echo ==========================================
echo.

:: Navigate to project root
cd /d "%~dp0..\.."

:: Check if Docker is running
echo [CHECK] Checking Docker status...
docker version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARNING] Docker is not running.
    echo [INFO] Nothing to stop.
    echo.
    pause
    exit /b 0
)

echo [INFO] Docker is running.
echo.

:: Check if any TripRadar containers are running
echo [CHECK] Looking for TripRadar containers...
docker ps --filter "name=trip-radar" --format "table {{.Names}}\t{{.Status}}" 2>nul | findstr /i trip-radar >nul
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] No TripRadar containers are currently running.
    echo.
    pause
    exit /b 0
)

:: Show running containers
echo Current TripRadar containers:
echo ------------------------------
docker ps --filter "name=trip-radar" --format "table {{.Names}}\t{{.Status}}"
echo.

:: Stop containers
echo [STOP] Stopping TripRadar services...
docker-compose -f docker-compose.yml -f docker-compose.override.yml down

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo    SUCCESS! TripRadar Backend Stopped
    echo ==========================================
    echo.
    echo All TripRadar services have been stopped.
    echo Data volumes are preserved.
    echo.
    echo Quick Actions:
    echo --------------
    echo - Restart services: Run start.bat
    echo - Clean all data:   Run clean.bat
    echo.
    
    :: Optional: Stop Docker Desktop
    choice /C YN /T 10 /D N /M "Do you want to stop Docker Desktop as well?"
    if !ERRORLEVEL! EQU 1 (
        echo.
        echo [DOCKER] Stopping Docker Desktop...
        
        :: Try multiple methods to stop Docker
        taskkill /f /im "Docker Desktop.exe" >nul 2>&1
        taskkill /f /im "com.docker.service" >nul 2>&1
        taskkill /f /im "dockerd.exe" >nul 2>&1
        
        :: Check if stopped
        timeout /t 2 /nobreak >nul
        tasklist /FI "IMAGENAME eq Docker Desktop.exe" 2>nul | find /I /N "Docker Desktop.exe" >nul
        if %ERRORLEVEL% NEQ 0 (
            echo [SUCCESS] Docker Desktop stopped.
        ) else (
            echo [WARNING] Docker Desktop may still be running.
            echo [INFO] You can stop it manually from the system tray.
        )
    ) else (
        echo.
        echo [INFO] Docker Desktop will continue running.
    )
) else (
    echo.
    echo [ERROR] Error stopping TripRadar Backend!
    echo.
    echo Troubleshooting:
    echo - Try running: docker-compose down
    echo - Check for errors: docker-compose logs
    echo.
)

echo.
pause