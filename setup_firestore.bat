@echo off
echo ================================
echo   FIRESTORE API SETUP SCRIPT
echo ================================
echo.
echo This script will help you enable Firestore API for project: rizz-7e0b8
echo.

echo Step 1: Opening Google Cloud Console to enable Firestore API...
start "" "https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=rizz-7e0b8"
echo.

echo Step 2: Opening Firebase Console to create Firestore database...
timeout /t 3 >nul
start "" "https://console.firebase.google.com/project/rizz-7e0b8/firestore"
echo.

echo ================================
echo   MANUAL STEPS TO COMPLETE:
echo ================================
echo.
echo In the first browser tab (Google Cloud Console):
echo   1. Click the blue "ENABLE" button
echo   2. Wait for "API enabled" confirmation
echo.
echo In the second browser tab (Firebase Console):
echo   1. Click "Create database"
echo   2. Choose "Start in test mode"
echo   3. Select your region (closest to you)
echo   4. Click "Done"
echo.
echo After completing both steps, restart your Flutter app.
echo.
echo Press any key to close this window...
pause >nul
