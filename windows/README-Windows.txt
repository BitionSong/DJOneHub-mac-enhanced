DJOneHub for Windows amd64
==========================

Install
-------
1. Extract the complete ZIP archive.
2. Double-click "Install DJOneHub.cmd".
3. Connect the DJI first-generation 4G module and install its Windows serial
   driver if Windows does not expose a COM port.
4. Start DJOneHub from the Start menu.

DJOneHub automatically enumerates Windows COM ports and probes for the module.
When ready, it opens an Edge App window. If Edge is unavailable, it opens the
local control panel in the default browser: http://127.0.0.1:7575

Stop and uninstall
------------------
- Use "Stop DJOneHub.cmd" from the extracted package to stop the background app.
- Use "Uninstall DJOneHub" from the Start menu to remove the installed files.

Logs
----
%LOCALAPPDATA%\DJOneHub\logs\djonehub.log

Current Windows capability boundary
-----------------------------------
- Available when the module exposes a usable Windows COM port: status, AT
  control, SMS, call-state control, GPS queries and the embedded control panel.
- Not yet equivalent to macOS: direct vendor USB AT/eSIM, automatic USB network
  service policy, module-side ADB voice setup, bidirectional call audio, native
  macOS notifications, Contacts and MapKit.
- This candidate is cross-compiled on macOS. It requires validation on a real
  Windows amd64 PC with the module before public release.

DJOneHub is an unofficial third-party project and is not affiliated with DJI,
Quectel, carriers or eSIM vendors.
