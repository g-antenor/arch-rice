import QtQuick
Column {
    id: root
    property string pending: ""
    readonly property var actions: [{id:"suspend",label:"Suspender",icon:"\uf186"}, {id:"poweroff",label:"Desligar",icon:"\uf011"}, {id:"reboot",label:"Reiniciar",icon:"\uf021"}, {id:"logout",label:"Encerrar sessão",icon:"\uf08b"}]
    function reset() { pending = "" }
    spacing: 12
    Text { text: root.pending ? "Confirmar " + root.actions.find(a => a.id === root.pending).label.toLowerCase() + "?" : "Energia"; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
    Repeater {
        model: root.pending ? [] : root.actions
        delegate: Rectangle {
            required property var modelData
            width: root.width; height: 38; radius: Theme.radius; color: Theme.surface
            Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: Theme.accent; font.family: Theme.font; font.pixelSize: 16 }
            Text { x: 40; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !Desktop.busy; onClicked: root.pending = modelData.id }
        }
    }
    Row {
        visible: root.pending.length > 0
        spacing: 12
        ActionButton { width: 110; label: "Confirmar"; available: !Desktop.busy; tint: Theme.danger; onTriggered: Desktop.run(["power", root.pending]) }
        ActionButton { width: 100; label: "Cancelar"; available: !Desktop.busy; onTriggered: root.pending = "" }
    }
    Text { width: parent.width; visible: Desktop.error.length > 0; text: Desktop.error; color: Theme.danger; wrapMode: Text.Wrap; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
}
