@echo off
rem Headless dialog tree layout: measure, --place and --check nodes. See LayoutTool.gd.
rem Example: layout.bat --layout=act/eden/my_tree --place --check
rem Relies on harem-heaven being a sibling checkout, like the export path does.
"%~dp0..\harem-heaven\executable\Godot_v4.1-stable_win64_console.exe" --headless --path "%~dp0." -- %*
exit /b %ERRORLEVEL%
