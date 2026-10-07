#!/bin/bash
# useapi.net — clean Google sign-in for the API (Linux: Ubuntu and other desktops, and WSL with WSLg on Windows 11).
# Run: bash google-account-setup-linux.sh [flow | notebook | vids | <url>]
# Opens Brave (deb, snap or flatpak; Ungoogled Chromium / Chromium as a fallback) in a brand-new, empty profile at Google
# Flow, Gemini Notebook or Google Vids (a menu asks unless the argument says). You sign in and copy the cookies by hand
# as the setup page shows. When the browser closes, this script deletes the whole profile, so that sign-in is never
# used by a browser again and the cookies the API holds stay valid. On WSL you can also simply run the Windows version (google-account-setup-windows.cmd).
step() { echo; echo "==> $*"; }
info() { echo "    $*"; }

echo
echo "=================================================================="
echo "  useapi.net - clean Google sign-in for the API"
echo "=================================================================="
echo
echo "Why this is needed:"
echo "  The API works with your Google account's session cookies. They work best when"
echo "  no browser keeps using the same sign-in (for Google Vids this is required: a"
echo "  browser that keeps using it breaks the API's copy within minutes). This script"
echo "  gives you a sign-in that only the API will ever use:"
echo "   - a brand-new, empty browser profile (no other accounts, history or extensions);"
echo "   - device-bound sessions switched off, so the cookies work outside this computer;"
echo "   - the profile is deleted when you close the browser, so this sign-in can never be"
echo "     opened in a browser again."
echo "  Nothing is read or sent by this script: you copy the cookies yourself."

# Which service: first argument (flow | notebook | vids | a URL), otherwise a menu
URL="$1"
case "$URL" in
  flow) URL=https://flow.google.com ;;
  notebook) URL=https://notebook.google.com ;;
  vids) URL=https://docs.google.com/videos ;;
esac
if [ -z "$URL" ]; then
  step "Which service are you setting up?"
  info "1) Google Flow"
  info "2) Gemini Notebook (NotebookLM)"
  info "3) Google Vids"
  info "4) Enter my own URL"
  read -r -p "    Enter 1, 2, 3 or 4: " CHOICE
  case "$CHOICE" in
    1) URL=https://flow.google.com ;;
    2) URL=https://notebook.google.com ;;
    3) URL=https://docs.google.com/videos ;;
    4) read -r -p "    URL: " URL ;;
    *) info "Unknown choice '$CHOICE'. Run this file again."; exit 1 ;;
  esac
  [ -z "$URL" ] && { info "No URL entered. Run this file again."; exit 1; }
fi
case "$URL" in
  *flow.google.com*) COPY="the https://accounts.google.com cookies" ;;
  *notebook.google.com*) COPY="the https://notebook.google.com AND the https://accounts.google.com cookies" ;;
  *docs.google.com*) COPY="the https://docs.google.com cookies" ;;
  *) COPY="the cookies the setup page lists" ;;
esac

step "Looking for Brave"
# Snap and flatpak browsers are sandboxed: they cannot see /tmp, so their profile goes under the home folder
BROWSER=() SANDBOXED=""
for b in /usr/bin/brave-browser /opt/brave.com/brave/brave-browser; do
  [ -x "$b" ] && { BROWSER=("$b"); break; }
done
if [ ${#BROWSER[@]} -eq 0 ] && [ -x /snap/bin/brave ]; then BROWSER=(/snap/bin/brave); SANDBOXED=snap; fi
if [ ${#BROWSER[@]} -eq 0 ] && command -v flatpak >/dev/null 2>&1 && flatpak info com.brave.Browser >/dev/null 2>&1; then
  BROWSER=(flatpak run com.brave.Browser); SANDBOXED=flatpak
fi
if [ ${#BROWSER[@]} -eq 0 ]; then
  for b in /usr/bin/ungoogled-chromium /usr/bin/chromium /usr/bin/chromium-browser /snap/bin/chromium; do
    if [ -x "$b" ]; then
      BROWSER=("$b"); case "$b" in /snap/*) SANDBOXED=snap ;; esac
      info "Brave not found; using $b instead."
      break
    fi
  done
fi
if [ ${#BROWSER[@]} -eq 0 ]; then
  info "No Brave (or Chromium) found. Install Brave: https://brave.com/linux/ and run this file again."
  exit 1
fi
info "Found: ${BROWSER[*]}${SANDBOXED:+ ($SANDBOXED)}"
if grep -qi microsoft /proc/version 2>/dev/null && [ -z "$WAYLAND_DISPLAY$DISPLAY" ]; then
  info "WSL without a display (WSLg needs Windows 11). Run google-account-setup-windows.cmd from Windows instead."
  exit 1
fi

step "Creating a temporary, empty browser profile"
if [ -n "$SANDBOXED" ]; then
  PROFILE="$(mktemp -d "$HOME/useapi-google-setup.XXXXXX")"
else
  PROFILE="$(mktemp -d "${TMPDIR:-/tmp}/useapi-google-setup.XXXXXX")"
fi
# Never start the browser without a fresh folder: an empty --user-data-dir would open the user's normal profile
if [ -z "$PROFILE" ] || [ ! -d "$PROFILE" ]; then
  info "Could not create a temporary folder. Check free space and permissions, then run this file again."
  exit 1
fi
[ "$SANDBOXED" = flatpak ] && BROWSER=(flatpak run "--filesystem=$PROFILE" com.brave.Browser)
info "Profile folder: $PROFILE"
info "It holds this sign-in only and is deleted at the end."

# The browser's helper processes can keep writing for a moment after it closes: retry the delete for up to ~20 s
cleanup() {
  step "Deleting the temporary profile"
  info "$PROFILE"
  for i in 1 2 3 4 5 6 7 8 9 10; do
    rm -rf "$PROFILE" 2>/dev/null
    if [ ! -d "$PROFILE" ]; then
      info "Deleted. This sign-in can no longer be opened in a browser; only the API uses it now."
      info "Do not sign in to this Google account in any other browser either."
      echo
      return
    fi
    info "The browser is still closing, retrying in 2 s ($i/10)"
    sleep 2
  done
  info "Could not delete it. Close every browser window opened by this setup, then delete that folder by hand."
  echo
  exit 1
}
trap cleanup EXIT

step "Starting the browser with the clean profile"
info "Page: $URL"
info "Switches:"
info "  --user-data-dir=<profile above>   use the empty profile, separate from your normal browser"
info "  --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions"
info "                                    do not bind the sign-in to this device (bound cookies are refused by the API)"
info "  --no-first-run --no-default-browser-check   skip the welcome screens"

step "Now, in the browser window:"
info "1. Sign in to your dedicated Google account."
info "2. Open Developer Tools (F12) > Application > Cookies, copy $COPY"
info "   and paste them into the useapi.net setup form, as the setup page shows."
info "3. When the form shows the account as added, CLOSE every window of this browser."
info "Keep this terminal open: it deletes the profile once the browser has closed."
info "Waiting for the browser to close..."

# Runs in the foreground until this browser instance exits (a separate profile = a separate instance, even if one is open)
"${BROWSER[@]}" --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check \
  --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions "$URL" >/dev/null 2>&1
info "The browser has closed."
