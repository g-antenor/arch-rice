pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io
import Quickshell.Services.UPower
Singleton {
    id: root
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.ready ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var microphone: source && source.ready ? source.audio : null
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    property var network: ({ connected: false, interface: "", address: "", wireless: false })
    property bool recordingOverride: false
    readonly property bool recording: recordingOverride || systemState.recording === true
    property var systemState: ({})
    property bool volumeVisible: false
    PwObjectTracker { objects: [root.source, ...root.streams].filter(n => n !== null) }
    Process {
        id: statusProcess
        command: ["python3", Qt.resolvedUrl("helpers/status.py").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const state = JSON.parse(text); root.systemState = state; root.network = state.network } catch (e) { console.warn("Status:", e) }
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: if (!statusProcess.running) statusProcess.running = true }
    IpcHandler {
        target: "controls"
        function setVolume(value: real): void { root.setVolume(value) }
        function muteMicrophone(muted: bool): void { if (root.microphone) root.microphone.muted = muted }
        function recording(active: bool): void { root.recordingOverride = active }
        function dnd(active: bool): void { Notifications.doNotDisturb = active }
        function status(): string { return JSON.stringify({ volume: root.volume, micMuted: root.microphone ? root.microphone.muted : null, recording: root.recording, network: root.network, notifications: Notifications.items.length, popup: Notifications.showing, popupTitle: Notifications.current ? Notifications.current.summary : "", streams: root.streams.length }) }
    }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    function showVolume() { volumeVisible = true; volumeTimer.restart() }
    function setVolume(value) { if (audio) audio.volume = Math.max(0, Math.min(1, value)) }
    Connections {
        target: root.audio
        function onVolumeChanged() { root.showVolume() }
        function onMutedChanged() { root.showVolume() }
    }
    Timer { id: volumeTimer; interval: 1500; onTriggered: root.volumeVisible = false }
}
