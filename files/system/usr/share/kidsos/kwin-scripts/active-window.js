// Loaded on demand by kidsos-safety-agent via org.kde.KWin's Scripting
// D-Bus interface (see files/apps/safety-agent/src/app/ActiveApplicationProviders.cpp).
// KWin's scripting sandbox has no file-system access, so the only way
// to get a value back out is print(), which the calling process reads
// from the systemd journal (unit kwin_wayland/kwin_x11) immediately
// after running the script. Best-effort by design — spec §14/§15
// already expect this to sometimes fail to resolve, hence
// capture_quality on SafetyEvent.
print("KIDSOS_ACTIVE_WINDOW:" + (workspace.activeWindow ? workspace.activeWindow.resourceClass : ""));
