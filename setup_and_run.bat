@echo off
echo [1/5] Creating clean directories without spaces...
if not exist "C:\src" mkdir "C:\src"
if not exist "C:\Projects" mkdir "C:\Projects"

echo [2/5] Moving Flutter SDK to C:\src\flutter...
if not exist "C:\src\flutter" (
    robocopy "C:\Users\NOT FOUND\Downloads\Compressed\flutter_windows_3.47.5-stable\flutter" "C:\src\flutter" /E /MOVE /NFL /NDL /NJH /NJS
)

echo [3/5] Copying Project to C:\Projects\jarvis_billing_app...
if not exist "C:\Projects\jarvis_billing_app" (
    robocopy "C:\Users\NOT FOUND\Downloads\Compressed\flutter_billing_app-main\jarvis_billing_app-main" "C:\Projects\jarvis_billing_app" /E /NFL /NDL /NJH /NJS
)

echo [4/5] Setting environment variables...
set JAVA_HOME=C:\Java\jdk-17
set PATH=C:\src\flutter\bin;%JAVA_HOME%\bin;C:\Users\NOT FOUND\Downloads\Compressed\platform-tools-latest-windows\platform-tools;%PATH%

echo [5/5] Cleaning and running project on device...
cd /d "C:\Projects\jarvis_billing_app"
call flutter config --no-analytics
call flutter clean
call flutter pub get
call flutter run -d a44f446b
pause
