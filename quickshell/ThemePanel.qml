import QtQuick
Column {
    id: root
    spacing: 12
    Repeater {
        model: Theme.choices
        delegate: Rectangle {
            required property var modelData
            width: root.width; height: 42; radius: Theme.radius
            color: Theme.surface; border.width: Theme.name === modelData.name ? 1 : 0; border.color: Theme.accent
            Rectangle { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: modelData.name === "red" ? "#d45d5d" : (modelData.name === "mono" ? "#e7e7e7" : "#8f8aac") }
            Text { x: 36; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
            Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: Theme.name === modelData.name ? "✓" : ""; color: Theme.accent; font.family: Theme.textFont }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !Desktop.busy; onClicked: Desktop.run(["theme", modelData.name]) }
        }
    }
    Row {
        width: parent.width; spacing: 8
        ActionButton { label: "\uf03e"; hint: "Próximo wallpaper"; available: !Desktop.busy; onTriggered: Desktop.run(["next-wallpaper"]) }
        Text { text: "Wallpaper: " + ({mountain:"Mountain Dark", mono:"Monocromático", red:"Mountain Red"})[Theme.wallpaperName]; height: 28; verticalAlignment: Text.AlignVCenter; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
    }
    Text { width: parent.width; text: Desktop.error; visible: text.length > 0; wrapMode: Text.Wrap; color: Theme.danger; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
}
