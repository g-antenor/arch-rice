import QtQuick
import QtQuick.Controls
import Quickshell
Item {
    id: root
    property string page: "audio"
    property bool showTabs: true
    signal pageRequested(string name)
    component Label: Text { color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize; textFormat: Text.PlainText }
    Row {
        id: tabs
        visible: root.showTabs
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8; spacing: 8
        Repeater {
            model: [{id: "audio", icon: "\uf028", title: "Áudio"}, {id: "apps", icon: "\uf009", title: "Aplicativos"}, {id: "media", icon: "\uf001", title: "Mídia"}, {id: "network", icon: "\uf1eb", title: "Rede"}, {id: "notifications", icon: "\uf0f3", title: "Notificações"}, {id:"themes", icon:"\uf1fc", title:"Temas e wallpaper"}, {id:"power", icon:"\uf011", title:"Energia"}, {id:"captures", icon:"\uf030", title:"Capturas"}, {id:"keybinds", icon:"\uf11c", title:"Atalhos"}]
            delegate: ActionButton {
                required property var modelData
                width: 38; label: modelData.icon; hint: modelData.title
                active: root.page === modelData.id
                onTriggered: root.pageRequested(modelData.id)
            }
        }

    }
    Flickable {
        id: scroll
        x: 16; y: root.showTabs ? 48 : 16; width: parent.width - 32; height: parent.height - y - 16
        contentHeight: content.height; clip: true; boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            id: scrollbar
            width: 4; policy: ScrollBar.AsNeeded
            contentItem: Rectangle { implicitWidth: 4; radius: 2; color: scrollbar.pressed ? Theme.accent : Theme.border }
            background: Item {}
        }
        Column {
            id: content
            width: scroll.width - 16; spacing: 12
            Column {
                width: parent.width; spacing: 12; visible: root.page === "audio"
                Label { text: "Volume geral" }
                Row {
                    width: parent.width; spacing: 10
                    ActionButton { label: Services.muted ? "\uf026" : "\uf028"; available: !!Services.audio; active: !Services.muted; hint: "Silenciar saída"; onTriggered: Services.audio.muted = !Services.audio.muted }
                    AudioSlider { width: parent.width - 100; enabled: !!Services.audio; value: Services.audio ? Services.audio.volume : 0; onMoved: Services.setVolume(value) }
                    Label { text: Services.audio ? Services.volume + "%" : "—"; height: 28; verticalAlignment: Text.AlignVCenter }
                }
                Label { width: parent.width; text: Services.sink ? Services.sink.description : "Nenhuma saída de áudio"; color: Theme.muted; elide: Text.ElideRight; font.pixelSize: Theme.captionSize }
                Label { text: "Microfone"; visible: root.showTabs }
                Row {
                    visible: root.showTabs
                    width: parent.width; spacing: 10
                    ActionButton { label: Services.microphone && Services.microphone.muted ? "\uf131" : "\uf130"; available: !!Services.microphone; active: !!Services.microphone && !Services.microphone.muted; hint: "Silenciar microfone"; onTriggered: Services.microphone.muted = !Services.microphone.muted }
                    AudioSlider { width: parent.width - 100; enabled: !!Services.microphone; value: Services.microphone ? Services.microphone.volume : 0; onMoved: Services.microphone.volume = value }
                    Label { text: Services.microphone ? Math.round(Services.microphone.volume * 100) + "%" : "—"; height: 28; verticalAlignment: Text.AlignVCenter }
                }
                Label { visible: root.showTabs; width: parent.width; text: Services.source ? Services.source.description : "Nenhum microfone"; color: Theme.muted; elide: Text.ElideRight; font.pixelSize: Theme.captionSize }
                Column {
                    width: parent.width; visible: root.showTabs; spacing: 4
                    DataRow { width: parent.width; label: "Fuso horário"; value: "Brasília · UTC−03" }
                    DataRow { width: parent.width; label: "Relógio"; value: "24 horas" }
                    DataRow { width: parent.width; label: "Bateria"; value: Services.batteryPercent + "%"; visible: Services.hasBattery }
                }
            }
            Column {
                width: parent.width; spacing: 12; visible: root.page === "apps"
                Label { visible: Services.streams.length === 0; text: "Nenhum aplicativo usando áudio"; color: Theme.muted }
                Repeater {
                    model: Services.streams
                    delegate: Column {
                        required property var modelData
                        width: content.width; spacing: 3
                        Label { width: parent.width; text: modelData.properties["application.name"] || modelData.description || modelData.name; elide: Text.ElideRight }
                        Row {
                            width: parent.width; spacing: 10
                            ActionButton { label: modelData.audio && modelData.audio.muted ? "\uf026" : "\uf028"; available: modelData.ready; onTriggered: modelData.audio.muted = !modelData.audio.muted }
                            AudioSlider { width: parent.width - 100; enabled: modelData.ready; value: modelData.ready ? modelData.audio.volume : 0; onMoved: modelData.audio.volume = value }
                            Label { text: modelData.ready ? Math.round(modelData.audio.volume * 100) + "%" : "—"; height: 28; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                }
            }
            MediaCard { width: parent.width; visible: root.page === "media" }
            Column {
                width: parent.width; spacing: 12; visible: root.page === "network"
                Label { text: Services.network.connected ? "Rede conectada" : "Sem conexão de rede"; color: Services.network.connected ? Theme.accent : Theme.muted; font.pixelSize: Theme.titleSize }
                DataRow { width: parent.width; label: "Interface"; value: Services.network.interface || "—" }
                DataRow { width: parent.width; label: "Endereço IP"; value: Services.network.address || "—" }
                DataRow { width: parent.width; label: "Tipo"; value: Services.network.wireless ? "Wi-Fi" : "Cabeada"; visible: Services.network.connected }
                Label { width: parent.width; text: "Estado da interface local; não confirma acesso à internet."; color: Theme.muted; wrapMode: Text.Wrap; font.pixelSize: Theme.captionSize }
            }
            Column {
                width: parent.width; spacing: 10; visible: root.page === "notifications"
                Row {
                    spacing: 8
                    Label { text: Notifications.items.length + " notificações"; height: 28; verticalAlignment: Text.AlignVCenter }
                    ActionButton { label: "\uf1f8"; hint: "Limpar todas"; available: Notifications.items.length > 0; onTriggered: Notifications.dismissAll() }
                    ActionButton { label: Notifications.doNotDisturb ? "\uf1f6" : "\uf0f3"; hint: "Não perturbe"; active: Notifications.doNotDisturb; onTriggered: Notifications.doNotDisturb = !Notifications.doNotDisturb }
                }
                Label { visible: Notifications.items.length === 0; text: "Nenhuma notificação"; color: Theme.muted }
                Repeater {
                    model: [...Notifications.items].reverse()
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        width: content.width; height: notificationText.height + 20; radius: Theme.radius; color: Theme.surface
                        Column {
                            id: notificationText
                            x: 12; y: 10; width: parent.width - 60; spacing: 5
                            Label { width: parent.width; text: card.modelData.appName; color: Theme.accent; font.pixelSize: Theme.captionSize; elide: Text.ElideRight }
                            Label { width: parent.width; text: card.modelData.summary; wrapMode: Text.Wrap; font.bold: true }
                            Label { width: parent.width; text: card.modelData.body; visible: text.length > 0; wrapMode: Text.Wrap; maximumLineCount: 6; elide: Text.ElideRight; color: Theme.muted }
                            Flow {
                                width: parent.width; spacing: 4
                                Repeater {
                                    model: card.modelData.actions
                                    delegate: ActionButton { required property var modelData; width: Math.min(200, Math.max(60, modelData.text.length * 8)); label: modelData.text; hint: modelData.text; onTriggered: modelData.invoke() }
                                }
                            }
                        }
                        ActionButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 6; label: "×"; hint: "Dispensar"; onTriggered: card.modelData.dismiss() }
                    }
                }
            }
            Column {
                width: parent.width; spacing: 12; visible: root.page === "captures"
                Label { text: "Capturas de tela"; font.pixelSize: Theme.titleSize }
                Label { width: parent.width; text: "Print congela a tela. Selecione a região e use a engrenagem para editar."; wrapMode: Text.Wrap; color: Theme.muted }
                ActionButton { width: 220; label: "Editar última captura"; hint: "Abrir no editor"; onTriggered: Desktop.run(["capture-edit-last"]) }
                Label { width: parent.width; visible: Desktop.error.length>0; text: Desktop.error; color: Theme.danger; wrapMode: Text.Wrap }
            }
            Column {
                width: parent.width; spacing: 8; visible: root.page === "keybinds"
                Label { text: "Atalhos · Super = tecla Windows"; color: Theme.accent }
                Repeater {
                    model: [
                        ["Super + Espaço", "Buscar aplicativos"], ["Super + Shift + Q", "Fechar janela"], ["Super + Ctrl + Shift + Q", "Encerrar sessão (confirmar)"],
                        ["Super + Shift + P", "Menu de energia"], ["Super + Shift + B", "Ocultar Island e maximizar"], ["Super + Shift + T", "Trocar tema"], ["Super + Shift + W", "Trocar wallpaper"],
                        ["Print", "Selecionar captura congelada"], ["Shift + Print", "Capturar tela inteira"], ["Super + Shift + R", "Iniciar / finalizar gravação"], ["Super + Shift + V", "Clipboard"],
                        ["Super + N", "LazyVim"], ["Super + D", "Lazydocker"], ["Super + T", "Tmux"], ["Super + F", "Yazi · Enter abre arquivos"], ["Super + Q", "Terminal Kitty"], ["Esc", "Fechar painel / cancelar captura"]
                    ]
                    delegate: DataRow { required property var modelData; width: content.width; label: modelData[0]; value: modelData[1] }
                }
            }
            ThemePanel { width: parent.width; visible: root.page === "themes" }
            PowerPanel { width: parent.width; visible: root.page === "power"; onVisibleChanged: if (!visible) reset() }
        }
    }
}
