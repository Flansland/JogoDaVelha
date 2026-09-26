@echo off
cd /d "%~dp0..\.."
flutter pub get
if errorlevel 1 exit /b %errorlevel%
flutter build apk --release -t lib/admin_main.dart
if errorlevel 1 exit /b %errorlevel%
if not exist "Builds\Android\Admin" mkdir "Builds\Android\Admin"
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "Builds\Android\Admin\JogoDaVelha-Admin.apk" >nul
echo Admin Android pronto em Builds\Android\Admin\JogoDaVelha-Admin.apk
echo.
