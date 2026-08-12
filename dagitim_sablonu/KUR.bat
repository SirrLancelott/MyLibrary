@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Hedef makinede BIR KEZ calistirilir: veritabanini olusturur, semayi kurar
rem  ve baslangic verisini yukler. Tekrar calistirmak guvenlidir; sema betigi
rem  idempotenttir. Ancak 02_veri.sql kitap tablolarini bosaltip yeniden
rem  doldurur - uygulamada ekledikleriniz varsa onlar silinir.
rem ---------------------------------------------------------------------------

set SUNUCU=.\SQLEXPRESS
set VT=BenimKutuphanem

echo ============================================
echo  Benim Kutuphanem - Kurulum
echo  Sunucu: %SUNUCU%   Veritabani: %VT%
echo ============================================
echo.

echo [1/5] sqlcmd araniyor...
where sqlcmd >nul 2>&1
if errorlevel 1 goto :sqlcmdyok

echo [2/5] SQL Server baglantisi deneniyor...
sqlcmd -S %SUNUCU% -E -b -Q "SELECT 1;" >nul 2>&1
if errorlevel 1 goto :baglantiyok

echo [3/5] Veritabani olusturuluyor (yoksa)...
sqlcmd -S %SUNUCU% -E -b -Q "IF DB_ID('%VT%') IS NULL CREATE DATABASE [%VT%];"
if errorlevel 1 goto :hata

echo [4/5] Sema kuruluyor...
sqlcmd -S %SUNUCU% -E -d %VT% -b -i sql\01_sema.sql
if errorlevel 1 goto :hata

echo [5/5] Baslangic verisi yukleniyor...
sqlcmd -S %SUNUCU% -E -d %VT% -b -f 65001 -i sql\02_veri.sql
if errorlevel 1 goto :hata

echo.
echo Kontrol:
sqlcmd -S %SUNUCU% -E -d %VT% -b -Q "SET NOCOUNT ON; SELECT * FROM dbo.vw_Ozet;"

echo.
echo ============================================
echo  Kurulum tamamlandi.
echo.
echo  Simdi baslat.bat dosyasini calistirin.
echo  Giris:  admin / 1234   ya da   emir / 1234
echo.
echo  ONEMLI: Ilk giristen sonra uygulamadaki
echo  "Sifre" sekmesinden sifrenizi degistirin.
echo ============================================
pause
exit /b 0

:sqlcmdyok
echo.
echo HATA: sqlcmd bulunamadi.
echo.
echo Bu arac SQL Server ile birlikte gelir. Kurmak icin:
echo   - "Microsoft SQL Server Express" ve
echo   - "Microsoft Command Line Utilities for SQL Server (sqlcmd)"
echo paketlerini kurun, ardindan bu pencereyi kapatip tekrar deneyin.
pause
exit /b 1

:baglantiyok
echo.
echo HATA: %SUNUCU% adresine baglanilamadi.
echo.
echo  - SQL Server Express kurulu mu?
echo  - Ornek adi %SUNUCU% mu? Farkliysa bu dosyadaki SUNUCU satirini duzenleyin.
echo  - MSSQL$SQLEXPRESS servisi calisiyor mu? Kontrol icin:
echo        powershell -Command "Get-Service 'MSSQL$SQLEXPRESS'"
pause
exit /b 1

:hata
echo.
echo HATA: Kurulum yarida kesildi. Yukaridaki mesaja bakin.
pause
exit /b 1
