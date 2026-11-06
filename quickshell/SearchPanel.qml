import QtQuick
import QtQuick.Controls
import Quickshell
Item {
    id: root
    property string query: ""
    property int selected: 0
    signal closeRequested()
    implicitHeight: 76 + Math.max(1,Math.min(6,results.length))*58
    function normalized(s) { return String(s || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }
    readonly property var results: DesktopEntries.applications.values.filter(app => {
        const hay=normalized([app.name,app.genericName,app.comment,app.id,...app.keywords].join(" "))
        return normalized(query).split(/\s+/).every(word => hay.includes(word))
    }).sort((a,b) => a.name.localeCompare(b.name))
    function reset() { query=""; selected=0; input.forceActiveFocus() }
    function glyph(app) {
        const n=normalized(app.id+" "+app.name)
        if (n.includes("docker")) return "\uf1b2"
        if (n.includes("yazi")) return "\uf07b"
        if (n.includes("nvim") || n.includes("lazyvim")) return "\uf044"
        if (n.includes("tmux") || n.includes("kitty")) return "\uf120"
        if (n.includes("image") || n.includes("imagem")) return "\uf03e"
        if (n.includes("pdf")) return "\uf1c1"
        if (n.includes("video") || n.includes("vídeo")) return "\uf008"
        if (n.includes("record")) return "\uf03d"
        if (n.includes("code")) return "\uf121"
        if (n.includes("dolphin") || n.includes("files")) return "\uf07b"
        if (n.includes("htop")) return "\uf080"
        if (n.includes("vim")) return "\uf044"
        if (n.includes("firefox") || n.includes("browser")) return "\uf0ac"
        if (n.includes("settings") || n.includes("control")) return "\uf013"
        return "\uf009"
    }
    function launch(index) {
        const app=results[index]
        if (!app) return
        closeRequested()
        Qt.callLater(() => {
            if (app.runInTerminal) {
                const command=app.command.filter(arg => !/^%[fFuUdDnNickvm]$/.test(arg)).map(arg => arg.replace(/%%/g,"%"))
                Quickshell.execDetached({command:["kitty","--class","org.darkmountain.terminal","-e",...command],workingDirectory:app.workingDirectory || ""})
            } else app.execute()
        })
    }
    onQueryChanged: selected=0
    Rectangle { x: 16; y: 14; width: parent.width-32; height: 44; radius: Theme.radius; color: Theme.surface; border.color: Theme.border
        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: "\uf002"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 20 }
        TextField {
            id: input; x: 46; width: parent.width-84; height: parent.height
            text: root.query; onTextEdited: root.query=text
            placeholderText: "Buscar aplicativos…"; placeholderTextColor: Theme.muted
            color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize
            background: Item {}
            Keys.onEscapePressed: root.closeRequested()
            Keys.onDownPressed: { root.selected=Math.min(root.results.length-1,root.selected+1); list.positionViewAtIndex(root.selected,ListView.Contain) }
            Keys.onUpPressed: { root.selected=Math.max(0,root.selected-1); list.positionViewAtIndex(root.selected,ListView.Contain) }
            Keys.onReturnPressed: root.launch(root.selected)
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
            width: list.width; height: 56; radius: Theme.radius
            color: root.selected===index ? Theme.surface : "transparent"
            border.color: root.selected===index ? Theme.accent : "transparent"
            Rectangle {
                x: 10; y: 10; width: 36; height: 36; radius: Theme.radius; color: Theme.surface
                readonly property string glyph: root.glyph(row.modelData)
                Text { anchors.centerIn: parent; text: parent.glyph; font.family: Theme.font; font.pixelSize: 22; color: Theme.accent }
            }
            Text { x: 58; y: 9; width: parent.width-72; text: row.modelData.name; textFormat: Text.PlainText; elide: Text.ElideRight; font.family: Theme.textFont; font.pixelSize: Theme.textSize; color: Theme.text }
            Text { x: 58; y: 30; width: parent.width-72; text: row.modelData.genericName || row.modelData.comment || row.modelData.id; textFormat: Text.PlainText; elide: Text.ElideRight; font.family: Theme.textFont; font.pixelSize: Theme.captionSize; color: Theme.muted }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: root.selected=row.index; onClicked: root.launch(row.index) }
        }
    }
    Text { x: 22; y: 82; visible: root.results.length===0; text: "Nenhum aplicativo encontrado"; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
}
