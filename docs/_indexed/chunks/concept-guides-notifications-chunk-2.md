---
doc_id: concept/guides/notifications
chunk_id: concept/guides/notifications#chunk-2
heading_path: ["Terminal notifications", "Setup"]
chunk_type: prose
tokens: 215
summary: "Setup"
---

## Setup

Notifications must be enabled at the operating system level.

### Linux

Linux support is based on the [XDG specification](https://en.wikipedia.org/wiki/XDG) and utilizes D-BUS APIs, primarily the [`org.freedesktop.Notifications.Notify`](https://www.galago-project.org/specs/notification/0.9/x408.html#command-notify) method. Refer to your desktop distribution for more information.

Notifications will be sent using the `moon` application name (the current executable).

### macOS

- Open "System Settings" or "System Preferences"
- Select "Notifications" in the left sidebar
- Select your terminal application from the list (e.g., "Terminal", "iTerm", etc)
- Ensure "Allow notifications" is enabled
- Customize the other settings as desired

Notifications will be sent from your currently running terminal application, derived from the `TERM_PROGRAM` environment variable. If we fail to detect the terminal, it will default to "Finder".

### Windows

Requires Windows 10 or later.

- Open "Settings"
- Go to the "System" panel
- Select "Notifications & Actions" in the left sidebar
- Ensure notifications are enabled

Notifications will be sent from the "Windows Terminal" app if it's currently in use, otherwise from "Microsoft PowerShell".
