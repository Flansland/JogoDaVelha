@echo off
cd /d "%~dp0..\.."
flutter pub get
if errorlevel 1 exit /b %errorlevel%
flutter build apk --release -t lib/main.dart
if errorlevel 1 exit /b %errorlevel%
if not exist "Builds\Android\Player" mkdir "Builds\Android\Player"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "Builds\Android\Player\JogoDaVelha.apk" >nul
echo Player Android pronto em Builds\Android\Player\JogoDaVelha.apk
echo.
