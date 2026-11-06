import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
Item {
    id: root
    property string query: ""
    property var entries: []
    property int selected: 0
    property string error: ""
    readonly property var results: entries.filter(entry => entry.text.toLowerCase().includes(query.toLowerCase()))
    implicitHeight: 76+Math.max(1,Math.min(6,results.length))*58
    signal closeRequested()
    function reset() { query=""; selected=0; error=""; refresh.running=true; input.forceActiveFocus() }
    function copy(index) {
        if (!results[index] || Desktop.busy) return
        const ident=results[index].id
        closeRequested()
        Qt.callLater(() => Desktop.run(["clipboard-copy",ident]))
    }
    onQueryChanged: selected=0
    Process {
        id: refresh
        command: [Quickshell.env("HOME")+"/.local/bin/cliphist","list"]
        stdout: StdioCollector { id: listing }
        stderr: StdioCollector { id: errors }
        onExited: (code,status) => {
            if (code!==0) { root.error="Não foi possível carregar o histórico."; root.entries=[]; return }
            root.entries=listing.text.split("\n").filter(line => /^\d+\t/.test(line)).map(line => ({id:line.slice(0,line.indexOf("\t")),text:line.slice(line.indexOf("\t")+1)}))
            root.selected=0
        }
    }
    Rectangle {
        x: 16; y: 14; width: parent.width-32; height: 44; radius: Theme.radius; color: Theme.surface; border.color: Theme.border
        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\uf0ea"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 20 }
        TextField {
            id: input; x: 46; width: parent.width-84; height: parent.height
            text: root.query; onTextEdited: root.query=text
            placeholderText: "Buscar no clipboard…"; placeholderTextColor: Theme.muted
            color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; background: Item {}
            Keys.onEscapePressed: root.closeRequested()
            Keys.onDownPressed: { root.selected=Math.min(root.results.length-1,root.selected+1); list.positionViewAtIndex(root.selected,ListView.Contain) }
            Keys.onUpPressed: { root.selected=Math.max(0,root.selected-1); list.positionViewAtIndex(root.selected,ListView.Contain) }
            Keys.onReturnPressed: root.copy(root.selected)
        }
        ActionButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; label: "×"; hint: "Fechar · Esc"; onTriggered: root.closeRequested() }
    }
    ListView {
        id: list; x: 16; y: 68; width: parent.width-32; height: Math.min(6,root.results.length)*58
        clip: true; model: root.results; boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool image: /binary.*\b(png|jpg|jpeg|gif|webp|bmp|image)\b/i.test(modelData.text)
            width: list.width; height: 56; radius: Theme.radius
            color: root.selected===index ? Theme.surface : "transparent"; border.color: root.selected===index ? Theme.accent : "transparent"
            Rectangle { x: 10; y: 10; width: 36; height: 36; radius: Theme.radius; color: Theme.surface
                Text { anchors.centerIn: parent; text: row.image ? "\uf03e" : "\uf15c"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 22 }
            }
            Text { x: 58; y: 9; width: parent.width-72; text: row.modelData.text; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
            Text { x: 58; y: 30; text: row.image ? "Imagem · Enter para copiar" : "Texto · Enter para copiar"; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: root.selected=row.index; onClicked: root.copy(row.index) }
        }
    }
    Text { x: 22; y: 82; visible: root.results.length===0; text: refresh.running ? "Carregando…" : (root.error || "Clipboard vazio"); color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
}
