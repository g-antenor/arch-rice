import QtQuick
import Quickshell
Item {
    id: root
    readonly property var player: Services.player
    readonly property bool hasLength: !!player && player.lengthSupported && player.length > 0
    readonly property real position: player && player.positionSupported ? Math.max(0, player.position) : 0
    readonly property real length: hasLength ? player.length : 0
    readonly property string title: player ? (player.trackTitle || "Sem título") : "Silêncio nas montanhas"
    function time(value) {
        const seconds = Math.max(0, Math.floor(value || 0))
        const h = Math.floor(seconds / 3600)
        return (h ? h + ":" : "") + String(Math.floor(seconds / 60) % (h ? 60 : 100000)).padStart(h ? 2 : 1, "0") + ":" + String(seconds % 60).padStart(2, "0")
    }
    height: 146
    Timer { interval: 1000; repeat: true; running: root.visible && !!root.player && root.player.isPlaying; onTriggered: root.player.positionChanged() }
    Rectangle {
        id: artwork
        x: 0; y: 12; width: 76; height: 76; radius: Theme.radius; color: Theme.surface; clip: true
        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 26 }
        Image { id: cover; anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
    }
    Column {
        x: 92; y: 12; width: parent.width - x; spacing: 5
        Text { width: parent.width; text: root.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
        Text { width: parent.width; text: root.player ? (root.player.trackArtist || root.player.identity) : "Abra seu player para ouvir música"; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
        Row {
            spacing: 10
            ActionButton { label: "\uf048"; hint: "Anterior"; available: !!root.player && root.player.canGoPrevious; onTriggered: root.player.previous() }
            ActionButton { label: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; hint: "Reproduzir / pausar"; active: !!root.player && root.player.isPlaying; available: !!root.player && root.player.canTogglePlaying; onTriggered: root.player.togglePlaying() }
            ActionButton { label: "\uf051"; hint: "Próxima"; available: !!root.player && root.player.canGoNext; onTriggered: root.player.next() }
        }
    }
    AudioSlider {
        x: 0; y: 93; width: parent.width; height: 24
        enabled: root.hasLength && root.player.positionSupported && root.player.canSeek
        value: root.hasLength ? Math.min(1, root.position / root.length) : 0
        onMoved: if (enabled) root.player.position = value * root.length
    }
    Text { x: 0; y: 119; text: root.player && root.player.positionSupported ? root.time(root.position) : "—:—"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.captionSize }
    Text { anchors.right: parent.right; y: 119; text: root.hasLength ? root.time(root.length) : "—:—"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.captionSize }
}
