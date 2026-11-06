pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    readonly property bool hidden: focusState.hidden
    readonly property bool busy: action.running
    property string error: ""
    signal powerRequested()
    signal searchRequested()
    signal clipboardRequested()
    signal logoutRequested()
    property bool captureActive: false
    property string capturePath: ""
    property string captureScreen: ""
    property bool captureFull: false
    function run(args) {
        if (action.running) return
        error = ""
        action.command = ["python3", Qt.resolvedUrl("helpers/control.py").toString().replace("file://", ""), ...args]
        action.running = true
    }
    FileView {
        path: Theme.stateDirectory + "/focus.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter { id: focusState; property bool hidden: false }
    }
    Process {
        id: action
        stdout: StdioCollector {}
        stderr: StdioCollector { id: errors }
        onExited: (code, status) => { if (code !== 0) root.error = errors.text || "Não foi possível executar a ação." }
    }
    IpcHandler {
        target: "desktop"
        function clipboardMenu(): void { root.clipboardRequested() }
        function searchMenu(): void { root.searchRequested() }
        function logoutMenu(): void { root.logoutRequested() }
        function capture(path: string, monitor: string, full: bool): void { root.capturePath = path; root.captureScreen = monitor; root.captureFull = full; root.captureActive = true }
        function captureDone(): void { root.captureActive = false }
        function powerMenu(): void { root.error = ""; root.powerRequested() }
        function theme(name: string): void { root.run(["theme", name]) }
        function nextTheme(): void { root.run(["next-theme"]) }
        function state(): string { return JSON.stringify({ captureActive:root.captureActive, error:root.error, hidden: root.hidden, theme: Theme.name, wallpaper: Theme.wallpaperName, background: Theme.background.toString(), accent: Theme.accent.toString(), busy: root.busy }) }
    }
}
