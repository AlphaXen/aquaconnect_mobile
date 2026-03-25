@echo off
cd /d "%~dp0"

echo.
echo ========================================
echo   AquaConnect Server Starting...
echo ========================================
echo.

echo [1/3] Checking port 8000...
python -c "
import subprocess, sys
r = subprocess.run(['netstat','-aon'], capture_output=True, text=True, encoding='cp949')
for line in r.stdout.splitlines():
    if ':8000 ' in line and 'LISTENING' in line:
        pid = line.split()[-1]
        subprocess.run(['taskkill','/PID',pid,'/F'], capture_output=True)
        print('      Stopped PID', pid)
        sys.exit(0)
print('      Port 8000 is free')
"

echo [2/3] Checking packages...
pip show fastapi >nul 2>&1
if errorlevel 1 (
    echo       Installing packages...
    pip install -r requirements.txt -q
)

echo [3/3] Starting server on port 8000...
echo.
echo   Emulator : http://10.0.2.2:8000
echo   Device   : http://YOUR_PC_IP:8000
echo.
echo   Run "ipconfig" to find your PC IP (IPv4)
echo   Enter the address in app Settings.
echo.
echo   Press Ctrl+C to stop.
echo ========================================
echo.

python -m uvicorn server:app --host 0.0.0.0 --port 8000

echo.
echo [ERROR] Server stopped. See error above.
pause
