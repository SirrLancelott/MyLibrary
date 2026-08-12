@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Hedef makinede BIR KEZ calistirilir: veritabanini ve bos tablolari olusturur.
rem  Kitap verisi YUKLENMEZ - uygulama bos bir kutuphaneyle baslar.
rem
rem  Tekrar calistirmak guvenlidir: sema betigi idempotenttir, var olan
rem  tablolara ve girdiginiz kitaplara dokunmaz.
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

rem Zaten dolu bir kurulum varsa hicbir seye dokunma.
rem Bu kontrol, betigin yanlislikla tekrar calistirilmasina karsi korur.
for /f "usebackq tokens=*" %%s in (`sqlcmd -S %SUNUCU% -E -h -1 -W -Q "SET NOCOUNT ON; IF DB_ID('%VT%') IS NULL SELECT 'YOK' ELSE SELECT CAST((SELECT COUNT(*) FROM [%VT%].dbo.Kitaplar) AS VARCHAR(20));" 2^>nul`) do set DURUM=%%s
if not "%DURUM%"=="YOK" if not "%DURUM%"=="0" goto :zatenKurulu

echo [3/5] Veritabani olusturuluyor (yoksa)...
sqlcmd -S %SUNUCU% -E -b -Q "IF DB_ID('%VT%') IS NULL CREATE DATABASE [%VT%];"
if errorlevel 1 goto :hata

echo [4/5] Tablolar kuruluyor...
sqlcmd -S %SUNUCU% -E -d %VT% -b -i sql\01_sema.sql
if errorlevel 1 goto :hata

rem Sema betigi gelistirme kolayligi icin ikinci bir hesap da olusturur.
rem Dagitilan kopyada yalnizca admin kalir.
echo [5/5] Hesaplar duzenleniyor...
sqlcmd -S %SUNUCU% -E -d %VT% -b -Q "DELETE FROM dbo.Kullanicilar WHERE KullaniciAdi = N'emir';"
if errorlevel 1 goto :hata

echo.
echo Kontrol (bos kutuphane bekleniyor):
sqlcmd -S %SUNUCU% -E -d %VT% -b -Q "SET NOCOUNT ON; SELECT * FROM dbo.vw_Ozet;"

echo.
echo ============================================
echo  Kurulum tamamlandi. Kutuphane bos - kitaplari
echo  uygulama icinden kendiniz ekleyeceksiniz.
echo.
echo  Simdi baslat.bat dosyasini calistirin.
echo  Giris:  admin / 1234
echo.
echo  ONEMLI: Ilk giristen sonra uygulamadaki
echo  "Sifre" sekmesinden sifrenizi degistirin.
echo ============================================
pause
exit /b 0

:zatenKurulu
echo.
echo ============================================
echo  Kurulum zaten yapilmis.
echo.
echo  "%VT%" veritabani mevcut ve icinde %DURUM% kitap var.
echo  Hicbir sey degistirilmedi.
echo.
echo  Uygulamayi acmak icin: baslat.bat
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
