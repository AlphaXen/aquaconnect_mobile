#!/bin/bash
cd "$(dirname "$0")"

echo ""
echo "========================================"
echo "  AquaConnect 서버 시작 (macOS/Linux)"
echo "========================================"
echo ""

# 패키지 설치
echo "[1/2] 패키지 설치 확인 중..."
pip3 install -r requirements.txt -q

echo "[2/2] 서버 시작 중..."
echo ""
echo " 접속 주소:"
echo "   로컬 앱:        http://localhost:8000"
echo "   실제 기기(WiFi): http://$(hostname -I | awk '{print $1}'):8000"
echo ""
echo " 앱 설정 메뉴에서 위 주소를 입력하세요."
echo " 종료: Ctrl+C"
echo ""
echo "========================================"
echo ""

python3 -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
