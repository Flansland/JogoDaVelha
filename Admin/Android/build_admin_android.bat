@echo off
cd /d "%~dp0..\.."
flutter pub get
flutter build apk --release -t lib/admin_main.dart
if errorlevel 1 exit /b %errorlevel%
mkdir "Admin\Android" 2>nul
copy /Y "build\app\outputs\flutter-apk\app-release.apk" "Admin\Android\jogo_da_velha_admin.apk" >nul
 echo Admin Android pronto em Admin\Android
