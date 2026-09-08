@echo off
chcp 65001 > nul
title Hệ Thống Quản Lý Siêu Thị - POS & Dashboard Server

echo ======================================================================
echo          HỆ THỐNG QUẢN LÝ SIÊU THỊ (POS & DASHBOARD)
echo ======================================================================
echo.
cd /d "%~dp0app"

echo [1/3] Đang kiểm tra và giải phóng cổng 3000 nếu bị kẹt...
powershell -NoProfile -Command "Stop-Process -Id (Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue).OwningProcess -Force -ErrorAction SilentlyContinue"

echo [2/3] Đang mở trình duyệt vào http://localhost:3000 ...
start http://localhost:3000

echo [3/3] Đang khởi động Web Server...
echo.
echo ======================================================================
echo  * Dữ liệu bán hàng, kho, doanh thu trong SQL Server được giữ nguyên.
echo  * Để dừng ứng dụng, bạn chỉ cần đóng cửa sổ đen này.
echo ======================================================================
echo.
node server.js
pause

