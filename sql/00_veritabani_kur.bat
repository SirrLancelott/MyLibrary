@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set SUNUCU=.\SQLEXPRESS
set VT=BenimKutuphanem

echo ============================================
echo  BenimKutuphanem - Veritabani Kurulumu
echo  Sunucu: %SUNUCU%   Veritabani: %VT%
echo ============================================
echo.

echo [0/3] Veritabani var mi kontrol ediliyor...
sqlcmd -S %SUNUCU% -E -b -Q "IF DB_ID('%VT%') IS NULL CREATE DATABASE [%VT%];"
if errorlevel 1 goto :hata

echo [1/3] Sema kuruluyor (01_sema.sql)...
sqlcmd -S %SUNUCU% -E -d %VT% -b -i 01_sema.sql
if errorlevel 1 goto :hata

echo [2/3] Excel verisi aktariliyor (02_veri.sql)...
sqlcmd -S %SUNUCU% -E -d %VT% -b -f 65001 -i 02_veri.sql
if errorlevel 1 goto :hata

echo [3/3] Kontrol...
sqlcmd -S %SUNUCU% -E -d %VT% -b -Q "SET NOCOUNT ON; SELECT * FROM dbo.vw_Ozet;"

echo.
echo ============================================
echo  Kurulum tamamlandi.
echo  Giris: admin / 1234
echo ============================================
pause
exit /b 0

:hata
echo.
echo HATA: Betik calistirilamadi.
echo  - SQL Server (SQLEXPRESS) servisi calisiyor mu?
echo  - sqlcmd PATH icinde mi?
pause
exit /b 1
