import QtQuick
Item {
    id: root
    property string label
    property string value
    implicitHeight: 28
    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.42; text: root.label; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
    Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.56; text: root.value; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
}
