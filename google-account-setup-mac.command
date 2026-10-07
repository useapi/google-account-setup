#!/bin/bash
# useapi.net — clean Google sign-in for the API (macOS). Double-click in Finder, or run from Terminal.
# Opens Brave in a brand-new, empty profile at Google Flow, Gemini Notebook or Google Vids (a menu asks unless the first
# argument says: flow | notebook | vids | <url>). You sign in and copy
# the cookies by hand as the setup page shows. When Brave quits, this script deletes the whole profile, so that sign-in is
# never used by a browser again and the cookies the API holds stay valid.
# If a double-click will not open it (a downloaded file loses its run permission and macOS blocks files from the internet),
# open Terminal and run:  bash ~/Downloads/google-account-setup-mac.command
# If macOS only warns that it cannot verify the file: right-click > Open, or (macOS 15 and later) System Settings >
# Privacy & Security > Open Anyway.
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
echo "   - a brand-new, empty Brave profile (no other accounts, history or extensions);"
echo "   - device-bound sessions switched off, so the cookies work outside this Mac;"
echo "   - the profile is deleted when you quit Brave, so this sign-in can never be"
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
BRAVE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
[ -x "$BRAVE" ] || BRAVE="$HOME/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
if [ ! -x "$BRAVE" ]; then
  info "Brave was not found in /Applications or ~/Applications."
  info "Install it from https://brave.com and run this file again."
  exit 1
fi
info "Found: $BRAVE"

step "Creating a temporary, empty browser profile"
PROFILE="$(mktemp -d "${TMPDIR:-/tmp}/useapi-google-setup.XXXXXX")"
# Never start Brave without the new folder: an empty --user-data-dir would open the normal Brave profile instead
if [ -z "$PROFILE" ] || [ ! -d "$PROFILE" ]; then
  info "Could not create a temporary folder in ${TMPDIR:-/tmp}."
  exit 1
fi
info "Profile folder: $PROFILE"
info "It holds this sign-in only and is deleted at the end."

# Brave's helper processes can keep writing for a moment after it quits: retry the delete for up to ~20 s
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
    info "Brave is still closing, retrying in 2 s ($i/10)"
    sleep 2
  done
  info "Could not delete it. Quit every Brave window opened by this setup, then delete that folder by hand."
  echo
  exit 1
}
trap cleanup EXIT

step "Starting Brave with the clean profile"
info "Page: $URL"
info "Switches:"
info "  --user-data-dir=<profile above>   use the empty profile, separate from your normal Brave"
info "  --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions"
info "                                    do not bind the sign-in to this device (bound cookies are refused by the API)"
info "  --no-first-run --no-default-browser-check   skip Brave's welcome screens"

step "Now, in the Brave window:"
info "1. Sign in to your dedicated Google account."
info "2. Open Developer Tools (F12) > Application > Cookies, copy $COPY"
info "   and paste them into the useapi.net setup form, as the setup page shows."
info "3. When the form shows the account as added, QUIT this Brave: click its window, then Cmd+Q (closing the window is not enough)."
info "Keep this window open: it deletes the profile once Brave has quit."
info "Waiting for Brave to quit..."

# Runs in the foreground until this Brave instance quits (a separate profile = a separate Brave, even if one is open)
"$BRAVE" --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check \
  --disable-features=EnableBoundSessionCredentials,DeviceBoundSessions "$URL" >/dev/null 2>&1
info "Brave has quit."
