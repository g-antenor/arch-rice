import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
PanelWindow {
    id: root
    required property string outputName
    visible: Desktop.captureActive && Desktop.captureScreen === outputName
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dark-mountain-capture"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "black"
    property real startX: 0
    property real startY: 0
    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0
    property bool dragging: false
    function finish(edit) { if (sw > 1 && sh > 1) Desktop.run(["capture-finish", ""+sx,""+sy,""+sw,""+sh,""+width,""+height,edit ? "edit" : "save"]) }
    function select(x,y,w,h) { sx=x; sy=y; sw=w; sh=h }
    Connections {
        target: Desktop
        function onCaptureActiveChanged() {
            if (Desktop.captureActive && Desktop.captureScreen===root.outputName) Qt.callLater(() => { root.select(0,0,Desktop.captureFull ? root.screen.width : 0,Desktop.captureFull ? root.screen.height : 0); keyboard.forceActiveFocus() })
        }
    }
    Image { anchors.fill: parent; source: root.visible ? "file://"+Desktop.capturePath : ""; fillMode: Image.Stretch; cache: false }
    Rectangle { width: parent.width; height: root.sy; color: "#99000000" }
    Rectangle { y: root.sy+root.sh; width: parent.width; height: Math.max(0,parent.height-y); color: "#99000000" }
    Rectangle { y: root.sy; width: root.sx; height: root.sh; color: "#99000000" }
    Rectangle { x: root.sx+root.sw; y: root.sy; width: Math.max(0,parent.width-x); height: root.sh; color: "#99000000" }
    Rectangle { x: root.sx; y: root.sy; width: root.sw; height: root.sh; color: "transparent"; border.width: 1; border.color: Theme.accent }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPressed: mouse => { root.startX=mouse.x; root.startY=mouse.y; root.select(mouse.x,mouse.y,0,0); root.dragging=true }
        onPositionChanged: mouse => { if (pressed) root.select(Math.min(root.startX,mouse.x),Math.min(root.startY,mouse.y),Math.abs(mouse.x-root.startX),Math.abs(mouse.y-root.startY)) }
        onReleased: root.dragging=false
    }
    Rectangle {
        x: Math.max(8,Math.min(root.sx,root.width-width-8)); y: Math.min(root.height-height-8,root.sy+root.sh+12)
        width: toolbar.width+24; height: 48; radius: Theme.radius; color: Theme.background; border.color: Theme.border
        visible: !root.dragging
        Row {
            id: toolbar; x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Text { text: root.sw>1 ? Math.round(root.sw)+" × "+Math.round(root.sh) : "Arraste para selecionar"; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize; height: 30; verticalAlignment: Text.AlignVCenter }
            ActionButton { width: 100; label: "Salvar"; hint: "Salvar e copiar · Enter"; available: root.sw>1; onTriggered: root.finish(false) }
            ActionButton { label: "\uf013"; hint: "Editar captura · E"; available: root.sw>1; onTriggered: root.finish(true) }
            ActionButton { label: "×"; hint: "Cancelar · Esc"; onTriggered: Desktop.run(["capture-cancel"]) }
        }
    }
    Item {
        id: keyboard; focus: true
        Keys.onEscapePressed: Desktop.run(["capture-cancel"])
        Keys.onReturnPressed: root.finish(false)
        Keys.onPressed: event => { if (event.key===Qt.Key_E) { root.finish(true); event.accepted=true } }
    }
    IpcHandler {
        target: "capture-"+root.outputName
        function select(x: int,y: int,w: int,h: int): void { root.select(x,y,w,h) }
        function save(): void { root.finish(false) }
        function edit(): void { root.finish(true) }
        function cancel(): void { Desktop.run(["capture-cancel"]) }
        function state(): string { return JSON.stringify({visible:root.visible,x:root.sx,y:root.sy,width:root.sw,height:root.sh,source:Desktop.capturePath}) }
    }
}
