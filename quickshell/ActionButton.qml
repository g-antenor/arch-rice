import QtQuick
import QtQuick.Controls
Rectangle {
    id: root
    property int iconSize: 14
    property string label
    property string hint: ""
    readonly property bool tooltipOpen: hintPopup.visible
    property bool available: true
    property bool active: false
    property color tint: active ? Theme.accent : Theme.muted
    signal triggered()
    width: 30; height: 28; radius: Theme.radius
    color: pointer.containsMouse && available ? Theme.border : (active ? Theme.surface : "transparent")
    opacity: available ? 1 : 0.35
    Text { anchors.centerIn: parent; text: root.label; color: root.tint; font.pixelSize: root.iconSize; font.family: root.label.length > 2 ? Theme.textFont : Theme.font }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; enabled: root.available; cursorShape: Qt.PointingHandCursor; onClicked: root.triggered() }
    ToolTip {
        id: hintPopup
        parent: root
        y: root.height + 6
        visible: pointer.containsMouse && root.hint.length > 0
        text: root.hint
        delay: 600
        timeout: 4000
        popupType: Popup.Item
        focus: false
        modal: false
        dim: false
        margins: 8
        background: Rectangle { color: Theme.surface; border.width: 1; border.color: Theme.border; radius: Theme.radius }
        contentItem: Text { text: root.hint; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
    }
}
