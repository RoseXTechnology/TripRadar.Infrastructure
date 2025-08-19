@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo    TripRadar Backend - Clean All Data
echo ==========================================
echo.
echo    !!!! DANGER ZONE !!!!
echo.
echo This operation will DELETE (TripRadar only):
echo   [X] TripRadar containers (from docker-compose)
echo   [X] TripRadar volumes (data will be lost)
echo   [X] Database data stored in TripRadar volumes
echo   [X] Redis cache stored in TripRadar volumes
echo   [X] Logs and metrics kept in TripRadar volumes
echo   [X] Uploaded files kept in TripRadar volumes
echo.
echo Optional: You can also remove ALL unused Docker data (images, containers, networks, volumes) across your machine.
echo.
echo This action is IRREVERSIBLE!
echo ==========================================
echo.

:: Double confirmation for safety
choice /C YN /M "Are you ABSOLUTELY SURE you want to delete ALL data?"
if %ERRORLEVEL% NEQ 1 (
    echo.
    echo [CANCEL] Clean operation cancelled.
    echo [INFO] Your data is safe.
    pause
    exit /b 0
)

echo.
set /p CONFIRM_TEXT=Type "DELETE ALL" to confirm: 
if /i not "%CONFIRM_TEXT%"=="DELETE ALL" (
    echo.
    echo [CANCEL] Clean operation cancelled.
    echo [INFO] You must type "DELETE ALL" to proceed.
    pause
    exit /b 0
)

echo.
echo [START] Beginning cleanup process...
echo.

:: Locate docker-compose directory (supports sibling TripRadar.Server)
set "SCRIPT_DIR=%~dp0"
set "CANDIDATE1=%SCRIPT_DIR%..\.."
set "CANDIDATE2=%SCRIPT_DIR%..\..\..\TripRadar.Server"
    
if defined TRIPRADAR_SERVER_DIR (
    if exist "%TRIPRADAR_SERVER_DIR%\docker-compose.yml" (
        set "COMPOSE_DIR=%TRIPRADAR_SERVER_DIR%"
    )
)
    
if not defined COMPOSE_DIR if exist "%CANDIDATE1%\docker-compose.yml" set "COMPOSE_DIR=%CANDIDATE1%"
if not defined COMPOSE_DIR if exist "%CANDIDATE2%\docker-compose.yml" set "COMPOSE_DIR=%CANDIDATE2%"
    
if not defined COMPOSE_DIR (
    echo [ERROR] Could not locate docker-compose.yml
    echo [INFO] Checked:
    echo     - %CANDIDATE1%
    echo     - %CANDIDATE2%
    if defined TRIPRADAR_SERVER_DIR echo     - %TRIPRADAR_SERVER_DIR%
    echo [HINT] Set TRIPRADAR_SERVER_DIR env var to your TripRadar.Server path.
    pause
    exit /b 1
)
    
cd /d "%COMPOSE_DIR%"

:: Check if Docker is running
echo [1/4] Checking Docker status...
docker version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Docker is not running. Attempting to start Docker...
    
    :: Try to start Docker Desktop
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        :: Try alternative path
        start "" "%LOCALAPPDATA%\Docker\Docker Desktop.exe" 2>nul
    )
    
    echo [WAIT] Waiting for Docker to start (up to 60 seconds)...
    set COUNTER=0
    :WAIT_DOCKER_CLEAN
    timeout /t 5 /nobreak >nul
    docker version >nul 2>&1
    if %ERRORLEVEL% EQU 0 goto DOCKER_READY_CLEAN
    
    set /a COUNTER+=1
    if %COUNTER% GEQ 12 (
        echo.
        echo [ERROR] Docker failed to start.
        echo [INFO] Please start Docker Desktop manually and try again.
        pause
        exit /b 1
    )
    echo [WAIT] Still waiting for Docker... (%COUNTER%0 seconds)
    goto WAIT_DOCKER_CLEAN
)

:DOCKER_READY_CLEAN
echo [SUCCESS] Docker is running.
echo.

:: List what will be deleted
echo [2/4] Analyzing TripRadar resources...
echo.
echo Containers to be removed:
echo -------------------------
docker ps -a --filter "name=trip-radar" --format "- {{.Names}}" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo - None found
)
echo.

echo Volumes to be removed:
echo ----------------------
docker volume ls --filter "name=trip-radar" --format "- {{.Name}}" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo - None found
)
echo.

:: Stop and remove containers with volumes
echo [3/4] Removing TripRadar containers and volumes...
docker-compose -f docker-compose.yml -f docker-compose.override.yml down -v --remove-orphans --timeout 30

if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Some containers may not have been removed properly.
    echo [INFO] Attempting force removal...
    
    :: Force remove containers
    for /f "tokens=*" %%i in ('docker ps -aq --filter "name=trip-radar"') do (
        docker rm -f %%i 2>nul
    )
    
    :: Force remove volumes
    for /f "tokens=*" %%i in ('docker volume ls -q --filter "name=trip-radar"') do (
        docker volume rm -f %%i 2>nul
    )
)

:: Optional: Clean up Docker system (GLOBAL)
echo.
choice /C YN /T 10 /D N /M "Do you also want to remove ALL unused Docker data (global prune)?"
if !ERRORLEVEL! EQU 1 (
    echo.
    echo [4/4] Cleaning Docker system (GLOBAL)...
    docker system prune -af --volumes 2>nul
    set "PRUNE_MSG=[OK] Docker system globally pruned"
 ) else (
    echo.
    echo [SKIP] Global Docker prune skipped.
    set "PRUNE_MSG=[SKIP] Global prune skipped"
 )

:: Remove .env file if exists (optional)
echo.
choice /C YN /T 10 /D N /M "Do you also want to remove the .env configuration file?"
if !ERRORLEVEL! EQU 1 (
    if exist ".env" (
        del /f /q ".env" 2>nul
        echo [INFO] .env file removed.
    )
)

:: Final status
echo.
echo ==========================================
echo    CLEANUP COMPLETE!
echo ==========================================
echo.
echo Summary:
echo ---------
echo [OK] All TripRadar containers removed
echo [OK] All TripRadar volumes removed
echo [OK] All cached data cleared
echo %PRUNE_MSG%
echo.
echo Next Steps:
echo -----------
echo 1. Run start.bat to create fresh containers
echo 2. Update .env file with your API keys
echo 3. Services will initialize with clean data
echo.

pause