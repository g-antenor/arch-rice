import QtQuick
import QtQuick.Controls
import QtQuick.Effects
Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#000000"
    readonly property color ink: "#e7e7e7"
    readonly property color muted: "#888888"
    readonly property color accent: "#8f8aac"
    readonly property color line: "#303030"
    readonly property string mono: terminalFont.status===FontLoader.Ready ? terminalFont.name : "monospace"
    property bool authenticating: false
    property string message: ""
    property string pendingPower: ""
    property date now: new Date()
    function clockText() {
        const d=new Date(now.getTime()-3*60*60*1000)
        return String(d.getUTCHours()).padStart(2,"0")+":"+String(d.getUTCMinutes()).padStart(2,"0")
    }
    function login() {
        if (authenticating || !username.text.trim() || !password.text) return
        pendingPower=""; message="Autenticando…"; authenticating=true
        sddm.login(username.text.trim(),password.text,session.currentIndex)
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: "background.svg"
        fillMode: Image.PreserveAspectCrop
        layer.enabled: true
        layer.effect: MultiEffect { brightness: -0.2 }
    }
    component Glass: Rectangle {
        id: glass
        radius: 6; color: "transparent"; border.color: root.line; border.width: 1
        clip: true
        ShaderEffectSource {
            id: sample
            anchors.fill: parent
            sourceItem: wallpaper
            sourceRect: Qt.rect(glass.mapToItem(wallpaper,0,0).x, glass.mapToItem(wallpaper,0,0).y,glass.width,glass.height)
            live: true; hideSource: false; visible: false
        }
        MultiEffect { anchors.fill: parent; source: sample; blurEnabled: true; blurMax: 48; blur: 1; autoPaddingEnabled: false }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: "#eb000000"; border.color: root.line }
    }
    FontLoader { id: terminalFont; source: "fonts/Mono.ttf" }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now=new Date() }
    Connections {
        target: sddm
        function onLoginFailed() { root.authenticating=false; password.text=""; root.message="Acesso negado. Tente novamente."; password.forceActiveFocus() }
        function onLoginSucceeded() { root.message="Iniciando sessão…" }
    }
    component Caption: Text { color: root.muted; font.family: root.mono; font.pixelSize: 12; textFormat: Text.PlainText }
    component Entry: TextField {
        color: root.ink; placeholderTextColor: root.muted; font.family: root.mono; font.pixelSize: 14
        height: 44; leftPadding: 14; rightPadding: 14; selectionColor: root.accent; selectedTextColor: "#000000"
        enabled: !root.authenticating
        background: Rectangle { radius: 6; color: "#101010"; border.width: 1; border.color: parent.activeFocus ? root.accent : root.line }
    }
    component Command: Button {
        id: button
        property bool emphasized: false
        height: 40; font.family: root.mono; font.pixelSize: 12
        contentItem: Text { text: button.text; font: button.font; color: button.emphasized ? root.ink : root.muted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 6; color: button.hovered || button.down ? "#181818" : "#101010"; border.color: button.activeFocus || button.emphasized ? root.accent : root.line; border.width: 1 }
    }
    Glass {
        anchors.horizontalCenter: parent.horizontalCenter; y: 16; width: 112; height: 38
        radius: 6; border.color: root.line
        Text { anchors.centerIn: parent; text: root.clockText(); color: root.ink; font.family: root.mono; font.pixelSize: 14 }
    }
    Glass {
        id: panel
        anchors.centerIn: parent; width: Math.min(520,root.width-32); height: form.height+64
        radius: 6; border.color: root.line; border.width: 1
        Column {
            id: form; x: 32; y: 28; width: parent.width-64; spacing: 16
            Row { spacing: 10
                Text { text: ">_"; color: root.accent; font.family: root.mono; font.pixelSize: 22 }
                Text { text: "dark mountain"; color: root.ink; font.family: root.mono; font.pixelSize: 19 }
            }
            Caption { text: "login@"+sddm.hostName+"  ~ / sessão" }
            Rectangle { width: parent.width; height: 1; color: root.line }
            Column { width: parent.width; spacing: 8
                Caption { text: "usuário" }
                Entry { id: username; width: parent.width; text: userModel.lastUser || ""; placeholderText: "nome de usuário"; onAccepted: password.forceActiveFocus(); KeyNavigation.tab: password }
            }
            Column { width: parent.width; spacing: 8
                Caption { text: "senha" }
                Entry { id: password; width: parent.width; echoMode: TextInput.Password; passwordCharacter: "•"; placeholderText: "••••••••"; onAccepted: root.login(); KeyNavigation.tab: session }
            }
            Row { width: parent.width; spacing: 12
                ComboBox {
                    id: session; width: parent.width-112; height: 40
                    model: sessionModel; textRole: "name"; currentIndex: Math.max(0,sessionModel.lastIndex)
                    enabled: !root.authenticating; font.family: root.mono; font.pixelSize: 11
                    contentItem: Text { leftPadding: 12; rightPadding: 26; text: session.displayText; color: root.muted; font: session.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    background: Rectangle { radius: 6; color: "#101010"; border.color: session.activeFocus ? root.accent : root.line }
                    indicator: Text { x: session.width-24; y: 12; text: "⌄"; color: root.muted; font.family: root.mono }
                    delegate: ItemDelegate { width: session.width; text: model.name; font: session.font; contentItem: Text { text: model.name; color: root.ink; font: session.font; elide: Text.ElideRight } background: Rectangle { color: parent.highlighted ? "#202020" : "#101010" } }
                    popup: Popup {
                        y: session.height+4; width: session.width; padding: 4
                        background: Glass {}
                        contentItem: ListView { implicitHeight: Math.min(contentHeight,180); model: session.popup.visible ? session.delegateModel : null; clip: true; currentIndex: session.highlightedIndex }
                    }
                }
                Command { width: 100; text: root.authenticating ? "…" : "entrar ↵"; emphasized: true; enabled: !root.authenticating; onClicked: root.login() }
            }
            Caption { width: parent.width; height: 32; text: root.message || "Enter para entrar  ·  Tab para navegar"; wrapMode: Text.Wrap; color: root.message ? root.accent : root.muted }
        }
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter; y: panel.y+panel.height+20; spacing: 10
        Row {
            spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
            Command { width: 110; text: "suspender"; visible: sddm.canSuspend; onClicked: root.pendingPower="suspend" }
            Command { width: 110; text: "reiniciar"; visible: sddm.canReboot; onClicked: root.pendingPower="reboot" }
            Command { width: 110; text: "desligar"; visible: sddm.canPowerOff; onClicked: root.pendingPower="poweroff" }
        }
        Row {
            visible: root.pendingPower!==""; spacing: 10; anchors.horizontalCenter: parent.horizontalCenter
            Command { width: 140; text: "confirmar"; emphasized: true; onClicked: { const p=root.pendingPower; root.pendingPower=""; if (p==="suspend") sddm.suspend(); else if (p==="reboot") sddm.reboot(); else if (p==="poweroff") sddm.powerOff() } }
            Command { width: 110; text: "cancelar"; onClicked: root.pendingPower="" }
        }
    }
    Caption { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 24; text: "hyprland / mountain dark"; font.pixelSize: 11 }
    Component.onCompleted: { if (username.text) password.forceActiveFocus(); else username.forceActiveFocus() }
    Keys.onEscapePressed: { root.pendingPower=""; root.message=""; password.text="" }
}
