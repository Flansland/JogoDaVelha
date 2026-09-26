@echo off
cd /d "%~dp0..\.."
flutter pub get
if errorlevel 1 exit /b %errorlevel%
flutter build windows --release -t lib/main.dart
if errorlevel 1 exit /b %errorlevel%
if exist "Builds\Windows\Player" rmdir /s /q "Builds\Windows\Player"
mkdir "Builds\Windows\Player"
xcopy /E /I /Y "build\windows\x64\runner\Release\*" "Builds\Windows\Player\" >nul
if exist "Builds\Windows\Player\jogo_da_velha.exe" ren "Builds\Windows\Player\jogo_da_velha.exe" "Jogo Da Velha.exe"
echo Player Windows pronto em Builds\Windows\Player
echo.
