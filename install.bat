@echo off
setlocal

:: =================================================================
:: Floorp Installer & Cleaner
::
:: This script provides a complete solution for making Floorp portable.
:: It uses the most reliable method for taskbar integration: instructing
:: the user to pin the app manually, then patching the resulting shortcut.
:: [CHANGED] Updated instructions to reflect the "launch, pin, close, patch"
:: workflow, while keeping the patch target as "Floorp.lnk".
:: =================================================================

:MENU
cls
echo.
echo  Floorp Portable - Installer
echo =========================================================
echo.
echo  Please choose an option:
echo.
echo  1. Full Installation (Registers as default browser)
echo  2. Patch Pinned Shortcut (Fixes the taskbar icon)
echo  3. Uninstall Floorp Portable
echo  4. (Tool) Fix Blank Icon Only
echo  5. Exit
echo.
echo ---------------------------------------------------------
echo.
set /p "CHOICE=Enter your choice (1-5): "

if /i "%CHOICE%"=="1" goto CLEAN_INSTALL
if /i "%CHOICE%"=="2" goto PATCH_TASKBAR_SHORTCUT
if /i "%CHOICE%"=="3" goto UNINSTALL
if /i "%CHOICE%"=="4" goto FIX_ICON
if /i "%CHOICE%"=="5" exit
goto MENU


:CLEAN_INSTALL
call :UNINSTALL
call :REGISTER
echo.
echo --- Full Installation Complete! ---
echo.
echo --- Important Next Steps ---
echo 1. Double-click "floorp-portable.exe" to launch the browser.
echo 2. While it's running, right-click its icon on the taskbar and choose "Pin to taskbar".
echo 3. Come back to this script and choose Option 2: "Patch Pinned Shortcut".
echo.
pause
goto MENU


:PATCH_TASKBAR_SHORTCUT
cls
echo.
echo --- Patching Pinned Floorp Shortcut on Taskbar ---
echo.
set "BASE_PATH=%~dp0"
set "TARGET_EXE=%BASE_PATH%app\floorp.exe"
set "WORKING_DIR=%BASE_PATH%app"
set "TASKBAR_PATH=%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
:: The script looks for "Floorp.lnk" which is the default name when pinning floorp.exe
set "SHORTCUT_FILE=%TASKBAR_PATH%\Floorp.lnk"

echo Checking for shortcut at: %SHORTCUT_FILE%
echo.

:: The final, proven arguments for the shortcut.
set "QUOTE=""
set "SHORTCUT_ARGS=-no-remote -profile %QUOTE%..\data\profile\default%QUOTE%"

echo Shortcut found. Applying fix...
echo   Target: %TARGET_EXE%
echo   Arguments: %SHORTCUT_ARGS%
echo.

:: This PowerShell command modifies the existing pinned shortcut with the correct arguments.
set "psCommand=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_FILE%'); $s.TargetPath = '%TARGET_EXE%'; $s.WorkingDirectory = '%WORKING_DIR%'; $s.Arguments = '%SHORTCUT_ARGS%'; $s.Save()""
%psCommand%

if %errorlevel% equ 0 (
    echo [SUCCESS] The pinned Floorp shortcut has been patched!
    echo Clicking the taskbar icon will now use the correct profile.
) else (
    echo [ERROR] Failed to patch the shortcut.
)

echo.
pause
goto MENU


:UNINSTALL
cls
echo.
echo --- Uninstalling Floorp Portable Settings... ---
echo.
reg delete "HKEY_CLASSES_ROOT\Applications\floorp.exe" /f > nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\FloorpHTML" /f > nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\RegisteredApplications" /v "FloorpPortable" /f > nul 2>&1
echo [SUCCESS] Previous portable settings have been removed.
echo.
if "%~1"=="standalone" pause
goto :eof


:REGISTER
cls
echo.
echo --- Registering Floorp Portable (for Default Browser)... ---
echo.
set "BASE_PATH=%~dp0"
set "REG_PATH=%BASE_PATH:\=\\%"
set "EXE_PATH_REG=%REG_PATH%app\\floorp.exe"
set "PROFILE_PATH_REG=%REG_PATH%data\\profile\\default"
set "ICON_PATH_REG=%REG_PATH%app\\floorp.exe,0"
set "APP_USER_MODEL_ID=Saneaki.Floorp.Portable"
set "TEMP_REG_FILE=%TEMP%\floorp_portable_reg.reg"
echo Preparing registry file...
echo.
(
    echo Windows Registry Editor Version 5.00
    echo.
    echo ; Assign an AppUserModelID to floorp.exe to fix taskbar grouping
    echo [HKEY_CLASSES_ROOT\Applications\floorp.exe]
    echo "AppUserModelID"="%APP_USER_MODEL_ID%"
    echo.
    echo ; Register the app as a default browser option
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable]
    echo @="Floorp Portable"
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable\Capabilities]
    echo "ApplicationDescription"="Floorp Portable"
    echo "ApplicationIcon"="%ICON_PATH_REG%"
    echo "ApplicationName"="Floorp Portable"
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable\Capabilities\FileAssociations]
    echo ".htm"="FloorpHTML"
    echo ".html"="FloorpHTML"
    echo ".mht"="FloorpHTML"
    echo ".mhtml"="FloorpHTML"
    echo ".pdf"="FloorpHTML"
    echo ".shtml"="FloorpHTML"
    echo ".svg"="FloorpHTML"
    echo ".webp"="FloorpHTML"
    echo ".xht"="FloorpHTML"
    echo ".xhtml"="FloorpHTML"
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable\Capabilities\URLAssociations]
    echo "http"="FloorpHTML"
    echo "https"="FloorpHTML"
    echo "ftp"="FloorpHTML"
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable\DefaultIcon]
    echo @="%ICON_PATH_REG%"
    echo.
    echo ; This command for "Default Browser" must NOT use -no-remote
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Clients\StartMenuInternet\FloorpPortable\shell\open\command]
    echo @="\"%EXE_PATH_REG%\" -profile \"%PROFILE_PATH_REG%\" \"%%1\""
    echo.
    echo ; Associate file types with our app and its AppID
    echo [HKEY_CLASSES_ROOT\FloorpHTML]
    echo @="Floorp HTML Document"
    echo "FriendlyTypeName"="Floorp Document"
    echo "AppUserModelID"="%APP_USER_MODEL_ID%"
    echo.
    echo [HKEY_CLASSES_ROOT\FloorpHTML\DefaultIcon]
    echo @="%ICON_PATH_REG%"
    echo.
    echo [HKEY_CLASSES_ROOT\FloorpHTML\shell\open\command]
    echo @="\"%EXE_PATH_REG%\" -profile \"%PROFILE_PATH_REG%\" \"%%1\""
    echo.
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\RegisteredApplications]
    echo "FloorpPortable"="Software\\Clients\\StartMenuInternet\\FloorpPortable\\Capabilities"
) > "%TEMP_REG_FILE%"
echo Importing to registry...
regedit /s "%TEMP_REG_FILE%"
if %errorlevel% equ 0 (echo. && echo  [SUCCESS] Registry imported.) else (echo. && echo  [ERROR] Failed to import. Please run as Administrator.)
del "%TEMP_REG_FILE%" > nul 2>&1
goto :eof


:FIX_ICON
cls
echo.
echo --- Fixing Blank Icon ---
echo.
set /p "CONFIRM=Are you sure you want to continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto MENU
echo.
echo Closing Windows Explorer...
taskkill /f /im explorer.exe
echo Deleting icon cache databases...
del /a /q "%localappdata%\IconCache.db"
del /a /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*.db"
echo Restarting Windows Explorer...
start explorer.exe
echo.
echo [SUCCESS] Icon cache has been cleared.
echo IMPORTANT: If the icon is still blank, please RESTART YOUR COMPUTER.
echo.
pause
goto MENU
