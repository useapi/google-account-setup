# Google Account Setup — a clean, single-use Google sign-in for exporting cookies

Small scripts for Windows, macOS and Linux that give you a **clean, single-use Google sign-in** — a throwaway browser profile for exporting a Google account's session cookies, with Google's device-bound sessions (DBSC) switched off. Built for Google Flow (Veo), Gemini Notebook (NotebookLM) and Google Vids, and works with any Google page.

Each script opens Brave (or Chromium) in a brand-new, empty profile, waits while you sign in and copy the cookies by hand, and deletes that profile the moment you close the browser. The sign-in is never reused by a browser, which is what keeps the exported cookies valid. It is a tidy way to hand a Google account's cookies to an API or tool that signs in with them, without touching your everyday browser or your other Google accounts.

| Script | Platform |
|---|---|
| [`google-account-setup-windows.cmd`](./google-account-setup-windows.cmd) | Windows 10 / 11 |
| [`google-account-setup-mac.command`](./google-account-setup-mac.command) | macOS |
| [`google-account-setup-linux.sh`](./google-account-setup-linux.sh) | Linux (Ubuntu and other desktops), WSL with WSLg on Windows 11 |

## Why a clean sign-in

Tools that drive a Google account work with its session cookies, and those cookies keep working best when no browser keeps using the same sign-in. These scripts give you a sign-in that only the tool you hand the cookies to will ever use, by taking care of three things:

- **A fresh, empty profile.** No other Google accounts, history or extensions, and it runs separately from your normal Brave, which can stay open.
- **No device-bound sessions.** Chromium browsers on Windows and macOS now bind a Google sign-in to the device (Device Bound Session Credentials, DBSC), and cookies from a bound session are refused anywhere else. The scripts start Brave with `--disable-features=EnableBoundSessionCredentials,DeviceBoundSessions` so the exported cookies work off this machine.
- **The profile is deleted when you close the browser.** That sign-in can never be opened in a browser again, so only the tool you gave the cookies to uses it.

The scripts read nothing and send nothing — you copy the cookies yourself. Each script is short: read it before you run it.

## Quick start

1. Install [Brave](https://brave.com/) (on Linux, Chromium works too).
2. Get the script for your platform: open it above and use `Download raw file`, or copy its text into a file with the same name.
3. Run it:
   - **Windows:** double-click `google-account-setup-windows.cmd`. If Windows shows `Windows protected your PC`, click `More info`, then `Run anyway`.
   - **macOS:** in Terminal, run `bash ~/Downloads/google-account-setup-mac.command`.
   - **Linux / WSL:** run `bash google-account-setup-linux.sh`.
4. Choose where to sign in — pick a service from the menu (Google Flow, Gemini Notebook, Google Vids, or **enter your own URL**), or pass it as an argument: `flow`, `notebook`, `vids`, or any URL.
5. In the browser window: sign in to your dedicated Google account, open Developer Tools (`F12`) → `Application` → `Cookies`, copy the cookies the script names, and paste them into the form of the tool you are connecting the account to.
6. When that tool shows the account as added, close every window of the browser. On a Mac, quit it with `Cmd+Q`. The script then deletes the profile.

Keep the script's window open until it reports the profile was deleted. Do not sign in to the same Google account in any other browser afterwards.

## Why exported Google cookies stop working

Two things usually end a copied Google session:

- **A browser keeps using the same sign-in.** Google rotates the session cookies of a signed-in browser, and the copy you exported falls behind. With Google Vids this takes only minutes. Deleting the profile on close means no browser is left to do this.
- **The sign-in was bound to the device.** On Windows and macOS, Chromium browsers bind new Google sign-ins to the machine, and the exported cookies are refused anywhere else. The scripts start the browser with that feature switched off.

## Which cookies to copy

| Service | Start page | Copy the cookies of |
|---|---|---|
| Google Flow | `https://flow.google.com` | `https://accounts.google.com` |
| Gemini Notebook (NotebookLM) | `https://notebook.google.com` | `https://notebook.google.com` and `https://accounts.google.com` |
| Google Vids | `https://docs.google.com/videos` | `https://docs.google.com` |
| Your own URL | the page you enter | whatever the tool you are connecting asks for |

## What you will see

```
==================================================================
  useapi.net - clean Google sign-in for the API
==================================================================

==> Which service are you setting up?
==> Looking for Brave
    Found: ...
==> Creating a temporary, empty browser profile
    Profile folder: ...
==> Starting Brave with the clean profile
==> Now, in the Brave window:
    1. Sign in to your dedicated Google account.
    2. Open Developer Tools (F12) > Application > Cookies, copy ...
    3. When the form shows the account as added, close every window of this Brave.
    Waiting for Brave to close...
==> Deleting the temporary profile
    Deleted. This sign-in can no longer be opened in a browser; only the API uses it now.
```

## Browser support

- **Windows:** Brave, installed for all users or for the current user.
- **macOS:** Brave in `/Applications` or `~/Applications`.
- **Linux:** Brave from Brave's apt repository, the snap or the flatpak. Ungoogled Chromium or Chromium is used if Brave is missing. Snap and flatpak browsers are sandboxed, so their profile goes in your home folder instead of `/tmp`.
- **WSL:** needs WSLg (Windows 11) to show the browser window. Without it, run the Windows script instead.

Tested on Windows 11 and on Ubuntu 22.04 under WSL. The macOS script is reviewed line by line and runs on the stock bash 3.2, but has not been run on a real Mac yet. Reports are welcome in the [issues](https://github.com/useapi/google-account-setup/issues).

## Where this is used

These scripts were built for, and are used by, [useapi.net](https://useapi.net/?utm_source=github.com&utm_medium=referral&utm_campaign=google-account-setup) — an experimental REST API for AI services. Its Google APIs drive your own Google account and subscription, so you use your plan's allowance at consumer rates instead of metered developer-API pricing. The account-setup pages walk you through running one of these scripts:

- [Setup Google Flow](https://useapi.net/docs/start-here/setup-google-flow) — the Google Flow (Veo) video and image API.
- [Setup Gemini Notebook](https://useapi.net/docs/start-here/setup-gemini-notebook) — the NotebookLM (Gemini Notebook) API.
- Google Vids — when it launches.

Visit our [Discord server](https://discord.gg/w28uK3cnmF) or [Telegram channel](https://t.me/use_api) for support questions, and the [YouTube channel](https://www.youtube.com/@useapi-net) for guides and tutorials.

## License

The example code in this repository is released under the [MIT License](./LICENSE). It covers the example scripts only, not the useapi.net service or API.
