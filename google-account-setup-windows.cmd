@echo off
rem useapi.net - clean Google sign-in for the API (Windows). Double-click to run.
rem Opens Brave in a brand-new, empty profile at Google Flow, Gemini Notebook or Google Vids (a menu asks unless the first
rem argument says: flow, notebook, vids or a URL). You sign in and copy
rem the cookies by hand as the setup page shows. When Brave closes, this script deletes the whole profile, so that sign-in
rem is never used by a browser again and the cookies the API holds stay valid.
rem If Windows warns before running it: on "Windows protected your PC" click More info, then Run anyway;
rem on "Open File - Security Warning" click Run. Or first: right-click the file, Properties, tick Unblock, OK.
setlocal
set "URL=%~1"

echo.
echo ==================================================================
echo   useapi.net - clean Google sign-in for the API
echo ==================================================================
echo.
echo Why this is needed:
echo   The API works with your Google account's session cookies. They work best when
echo   no browser keeps using the same sign-in (for Google Vids this is required: a
echo   browser that keeps using it breaks the API's copy within minutes). This script
echo   gives you a sign-in that only the API will ever use:
echo    - a brand-new, empty Brave profile (no other accounts, history or extensions);
echo    - device-bound sessions switched off, so the cookies work outside this PC;
echo    - the profile is deleted when you close Brave, so this sign-in can never be
echo      opened in a browser again.
echo   Nothing is read or sent by this script: you copy the cookies yourself.

rem Which service: first argument (flow, notebook, vids or a URL), otherwise a menu
if /i "%URL%"=="flow" set "URL=https://flow.google.com"
if /i "%URL%"=="notebook" set "URL=https://notebook.google.com"
if /i "%URL%"=="vids" set "URL=https://docs.google.com/videos"
if not "%URL%"=="" goto haveurl
echo.
echo ==^> Which service are you setting up?
echo     1 - Google Flow
echo     2 - Gemini Notebook (NotebookLM)
echo     3 - Google Vids
echo     4 - Enter my own URL
set "CHOICE="
set /p "CHOICE=Enter 1, 2, 3 or 4: "
if "%CHOICE%"=="1" set "URL=https://flow.google.com"
if "%CHOICE%"=="2" set "URL=https://notebook.google.com"
if "%CHOICE%"=="3" set "URL=https://docs.google.com/videos"
if "%CHOICE%"=="4" (
    set /p "URL=    URL: "
    if not defined URL goto nourl
)
if "%URL%"=="" goto badchoice
:haveurl
set "COPY=the cookies the setup page lists"
echo "%URL%"| find /i "flow.google.com" >nul && set "COPY=the https://accounts.google.com cookies"
echo "%URL%"| find /i "notebook.google.com" >nul && set "COPY=the https://notebook.google.com AND the https://accounts.google.com cookies"
echo "%URL%"| find /i "docs.google.com" >nul && set "COPY=the https://docs.google.com cookies"

echo.
echo ==^> Looking for Brave
set "B=%ProgramFiles%\BraveSoftware\Brave-Browser\Application\brave.exe"
if not exist "%B%" set "B=%ProgramFiles(x86)%\BraveSoftware\Brave-Browser\Application\brave.exe"
if not exist "%B%" set "B=%LocalAppData%\BraveSoftware\Brave-Browser\Application\brave.exe"
if not exist "%B%" goto nobrave
echo     Found: "%B%"

echo.
echo ==^> Creating a temporary, empty browser profile
set "P=%TEMP%\useapi-google-setup-%RANDOM%%RANDOM%"
mkdir "%P%"
echo     Profile folder: "%P%"
echo     It holds this sign-in only and is deleted at the end.

echo.
echo ==^> Starting Brave with the clean profile
echo     Page: "%URL%"
echo     Switches:
echo       --user-data-dir=[profile above]  use the empty profile, separate from your normal Brave
echo       --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions
echo                                        do not bind the sign-in to this PC (bound cookies are refused by the API)
echo       --no-first-run --no-default-browser-check   skip Brave's welcome screens

echo.
echo ==^> Now, in the Brave window:
echo     1. Sign in to your dedicated Google account.
echo     2. Open Developer Tools (F12) ^> Application ^> Cookies, copy %COPY%
echo        and paste them into the useapi.net setup form, as the setup page shows.
echo     3. When the form shows the account as added, CLOSE every window of this Brave.
echo     Keep this window open: it deletes the profile once Brave has closed.
echo     Waiting for Brave to close...

start "" /wait "%B%" --user-data-dir="%P%" --no-first-run --no-default-browser-check --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions "%URL%"
echo     Brave has closed.

echo.
echo ==^> Deleting the temporary profile
echo     "%P%"
rem Brave's helper processes can keep files open for a moment after it closes: retry the delete for up to ~20 s
for /l %%i in (1,1,10) do (
    if exist "%P%" (
        rmdir /s /q "%P%" 2>nul
        if exist "%P%" (
            echo     Brave is still closing, retrying in 2 s [%%i/10]
            timeout /t 2 /nobreak >nul
        )
    )
)
set "RC=0"
if exist "%P%" (
    set "RC=1"
    echo     Could not delete it. Close every Brave window opened by this setup, then delete that folder by hand.
) else (
    echo     Deleted. This sign-in can no longer be opened in a browser; only the API uses it now.
    echo     Do not sign in to this Google account in any other browser either.
)
echo.
pause
exit /b %RC%

:badchoice
echo     Unknown choice. Run this file again and enter 1, 2, 3 or 4.
echo.
pause
exit /b 1

:nourl
echo     No URL entered. Run this file again.
echo.
pause
exit /b 1

:nobrave
echo     Brave was not found in Program Files or AppData.
echo     Install it from https://brave.com and run this file again.
echo.
pause
exit /b 1
