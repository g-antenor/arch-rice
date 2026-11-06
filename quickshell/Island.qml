import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
PanelWindow {
    id: root
    property bool hovered: false
    property bool calendarOpen: false
    property bool expanded: false
    property bool powerOpen: false
    property bool searchOpen: false
    property bool clipboardOpen: false
    visible: !Desktop.hidden
    readonly property bool revealed: hovered || expanded || calendarOpen || powerOpen || searchOpen || clipboardOpen
    readonly property bool showMedia: revealed && !expanded && !calendarOpen && !powerOpen && !searchOpen && !clipboardOpen && !popup
    function toggleCalendar() {
        calendarOpen = !calendarOpen
        expanded = false
        powerOpen = false
        if (calendarOpen) { calendarPanel.reset(); calendarPanel.forceActiveFocus() }
    }
    function closePanels() { clipboardOpen = false; searchOpen = false; expanded = false; calendarOpen = false; powerOpen = false; powerOptions.reset() }
    Timer { id: leaveTimer; interval: 400; onTriggered: root.hovered = false }
    property bool allSettings: false
    property string page: "audio"
    component HeaderButton: ActionButton {
        property bool shown: true
        width: shown ? 34 : 0
        height: 32; iconSize: 20
        visible: width > 0
        opacity: available ? Math.min(1, width / 34) : 0.35
        Behavior on width { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    }
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var workspace: monitor ? monitor.activeWorkspace : null
    readonly property var liveWorkspaceIds: Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id)
    property var workspaceIds: []
    function rememberWorkspaces() {
        const active = workspace && workspace.id > 0 ? [workspace.id] : []
        workspaceIds = [...new Set(workspaceIds.concat(liveWorkspaceIds, active))].sort((a,b) => a-b)
    }
    onLiveWorkspaceIdsChanged: rememberWorkspaces()
    onWorkspaceChanged: rememberWorkspaces()
    Component.onCompleted: rememberWorkspaces()
    readonly property bool popup: Notifications.showing && !Desktop.captureActive && !searchOpen && !clipboardOpen && !powerOpen && (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === screen.name)
    readonly property var notice: popup ? Notifications.current : null
    function openPage(name, full = false) {
        const same = expanded && page === name && allSettings === full
        calendarOpen = false
        searchOpen = false
        clipboardOpen = false
        powerOpen = false
        page = name; allSettings = full; expanded = !same
        if (expanded) settingsPanel.forceActiveFocus()
    }
    anchors.top: true
    margins.top: 2
    readonly property real workspaceSpace: revealed && workspaceIds.length > 1 ? workspaceRow.implicitWidth + 16 : 0
    readonly property real expectedControlsWidth: (3 + (Services.recording ? 1 : 0) + (Notifications.items.length > 0 ? 1 : 0)) * 38 - 4
    readonly property real restingWidth: revealed ? timeLabel.implicitWidth + 2 * Math.max(workspaceRow.implicitWidth, expectedControlsWidth) + 64 : timeLabel.implicitWidth + 64 + (Services.recording ? 32 : 0)
    implicitWidth: clipboardOpen ? Math.min(560,screen.width-4) : searchOpen ? Math.min(560,screen.width-4) : Math.min(popup ? noticeCard.desiredWidth : (powerOpen ? Math.max(380, restingWidth) : (calendarOpen ? Math.max(380, restingWidth) : (expanded ? Math.max(restingWidth, allSettings ? 560 : 420) : (revealed ? Math.max(restingWidth, 420) : restingWidth)))), screen.width - 4)
    implicitHeight: clipboardOpen ? clipboardPanel.implicitHeight : searchOpen ? searchPanel.implicitHeight : popup ? noticeCard.implicitHeight : (powerOpen ? 320 : (calendarOpen ? Math.min(372, screen.height - 6) : (expanded ? settingsPanel.y + settingsPanel.height : (showMedia ? 196 : 40))))
    exclusiveZone: Desktop.hidden ? 0 : 42
    color: "transparent"
    WlrLayershell.namespace: "dark-mountain-island"
    WlrLayershell.keyboardFocus: expanded || calendarOpen || powerOpen || searchOpen || clipboardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region {
        x: 6; width: Math.max(0, root.width - 12); height: root.height
        regions: [
            Region { y: 6; width: root.width; height: Math.max(0, root.height - 12) },
            Region { width: 12; height: 12; shape: RegionShape.Ellipse },
            Region { x: root.width - 12; width: 12; height: 12; shape: RegionShape.Ellipse },
            Region { y: root.height - 12; width: 12; height: 12; shape: RegionShape.Ellipse },
            Region { x: root.width - 12; y: root.height - 12; width: 12; height: 12; shape: RegionShape.Ellipse }
        ]
    }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    HyprlandFocusGrab {
        id: outsideGrab
        windows: [root]
        active: root.visible && (root.expanded || root.calendarOpen || root.powerOpen || root.searchOpen || root.clipboardOpen)
        onCleared: { root.closePanels(); root.hovered = false; leaveTimer.stop() }
    }
    Connections {
        target: Desktop
        function onClipboardRequested() {
            if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name===root.screen.name) { root.closePanels(); root.clipboardOpen=true; clipboardPanel.reset() }
        }
        function onSearchRequested() {
            if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === root.screen.name) {
                root.closePanels(); root.searchOpen=true; searchPanel.reset()
            }
        }
        function onLogoutRequested() {
            if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === root.screen.name) {
                root.closePanels(); root.powerOpen=true; powerOptions.pending="logout"; powerOptions.forceActiveFocus()
            }
        }
        function onPowerRequested() {
            if (!Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === root.screen.name) {
                root.closePanels(); root.powerOpen = true; powerOptions.forceActiveFocus()
            }
        }
        function onHiddenChanged() { if (Desktop.hidden) { root.closePanels(); root.hovered = false; leaveTimer.stop() } }
    }
    IpcHandler {
        target: "island-" + root.screen.name
        function toggle(): void { root.openPage("audio", true) }
        function close(): void { root.closePanels(); root.hovered = false; leaveTimer.stop() }
        function hover(active: bool): void { leaveTimer.stop(); root.hovered = active }
        function calendar(): void { root.toggleCalendar() }
        function nextMonth(delta: int): void { calendarPanel.navigate(delta) }
        function page(name: string): void { root.clipboardOpen=false; root.searchOpen=false; root.powerOpen = false; root.calendarOpen = false; root.page = name === "settings" ? "audio" : name; root.allSettings = name === "settings"; root.expanded = true; settingsPanel.forceActiveFocus() }
        function search(query: string): void { root.closePanels(); root.searchOpen=true; searchPanel.query=query; searchPanel.forceActiveFocus() }
        function clipboard(query: string): void { root.closePanels(); root.clipboardOpen=true; clipboardPanel.reset(); clipboardPanel.query=query }
        function clipboardState(): string { return JSON.stringify({open:root.clipboardOpen,count:clipboardPanel.results.length,selected:clipboardPanel.selected}) }
        function clipboardCopy(index: int): void { clipboardPanel.copy(index) }
        function searchState(): string { return JSON.stringify({open:root.searchOpen,query:searchPanel.query,results:searchPanel.results.map(a=>({name:a.name,id:a.id,terminal:a.runInTerminal,command:a.command,icon:a.icon})),selected:searchPanel.selected}) }
        function launch(index: int): void { searchPanel.launch(index) }
        function state(): string { return JSON.stringify({ clipboardOpen: root.clipboardOpen, idleRecording: idleRecording.visible, searchOpen: root.searchOpen, expanded: root.expanded, allSettings: root.allSettings, page: root.page, notificationCount: Notifications.items.length, noticeSummary: root.notice ? root.notice.summary : "", notificationIcon: Notifications.items.length > 0, workspaces: root.workspaceIds, dotsVisible: workspacePill.visible, dotCount: workspacePill.visible ? root.workspaceIds.length : 0, width: root.width, dateCenter: root.width/2, panelWidth: settingsPanel.width, restingWidth: root.restingWidth, controlsWidth: controlsRow.implicitWidth, clockText: timeLabel.text, iconSize: 20, clockX: timeLabel.x, clockWidth: timeLabel.implicitWidth, controlsX: controlsPill.x, workspaceSpace: root.workspaceSpace, hovered: root.hovered, revealed: root.revealed, calendarOpen: root.calendarOpen, calendarYear: calendarPanel.year, calendarMonths: 1, calendarMonth: calendarPanel.month, calendarDays: calendarPanel.days, calendarTitle: calendarPanel.title, timeZone: Theme.timezone, radius: Theme.radius, workspaceX: workspacePill.x, controlsRight: controlsPill.x + controlsPill.width, mediaVisible: mediaCard.visible, mediaTitle: mediaCard.title, mediaPosition: mediaCard.position, mediaLength: mediaCard.length, height: root.height, powerOpen: root.powerOpen, powerPending: powerOptions.pending, focusGrab: outsideGrab.active, hidden: Desktop.hidden, iconOpacities: controlsRow.children.filter(c => c.visible).map(c => c.opacity), tooltips: controlsRow.children.filter(c => c.visible).map(c => c.tooltipOpen) }) }
    }
    Rectangle {
        anchors.fill: parent
        HoverHandler {
            onHoveredChanged: {
                if (hovered) { leaveTimer.stop(); root.hovered = true }
                else leaveTimer.restart()
            }
        }
        radius: Theme.radius; color: Qt.alpha(Theme.background, 0.92); border.width: 1
        border.color: root.popup ? Theme.accent : Theme.border
    }
    Item {
        id: workspacePill
        visible: root.revealed && !root.searchOpen && !root.clipboardOpen && !root.popup && root.workspaceIds.length > 1
        x: 16; y: 0
        width: workspaceRow.implicitWidth; height: 40
        Row {
            id: workspaceRow
            anchors.centerIn: parent; spacing: 6
            Repeater {
                model: root.workspaceIds.length > 1 ? root.workspaceIds : []
                delegate: Item {
                    required property int modelData
                    width: 12; height: 40
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.workspace && root.workspace.id === parent.modelData ? 8 : 5; height: width; radius: width/2
                        color: root.workspace && root.workspace.id === parent.modelData ? Theme.accent : Theme.border
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.modelData + " })") }
                }
            }
        }
    }
    Item {
        id: controlsPill
        x: root.width - controlsRow.implicitWidth - 16
        visible: root.revealed && !root.searchOpen && !root.clipboardOpen && !root.popup
        y: 0; width: controlsRow.implicitWidth; height: 40
        Row {
            id: controlsRow
            anchors.centerIn: parent; spacing: 4
            HeaderButton { shown: Services.recording; label: "\uf03d"; tint: Theme.danger; hint: "Gravação em andamento"; onTriggered: root.openPage("audio", true) }
            HeaderButton {
                shown: Notifications.items.length > 0
                label: Notifications.doNotDisturb ? "\uf1f6" : "\uf0f3"
                hint: Notifications.items.length + " notificações"
                active: root.expanded && !root.allSettings && root.page === "notifications"
                onTriggered: root.openPage("notifications")
            }
            HeaderButton {
                label: Services.muted ? "\uf026" : "\uf028"; hint: Services.volume + "% · volume geral"
                active: root.expanded && !root.allSettings && root.page === "audio"
                onTriggered: root.openPage("audio")
            }
            HeaderButton {
                label: Services.network.connected ? (Services.network.wireless ? "\uf1eb" : "\uf0e8") : "\uf127"
                hint: Services.network.connected ? Services.network.interface + " · " + Services.network.address : "Sem rede"
                active: root.expanded && !root.allSettings && root.page === "network"
                onTriggered: root.openPage("network")
            }
            HeaderButton {
                label: "\uf013"; hint: "Todas as configurações"
                active: root.expanded && root.allSettings
                onTriggered: root.openPage("audio", true)
            }
        }
    }
    Item {
        id: settingsPanel
        anchors.right: parent.right
        y: 40
        width: root.width
        height: root.allSettings || root.page === "notifications" ? 290 : (root.page === "audio" ? 115 : 195)
        visible: root.expanded && !root.popup && !root.powerOpen
        focus: root.expanded
        Keys.onEscapePressed: root.closePanels()
        ControlPanel {
            anchors.fill: parent
            page: root.page
            showTabs: root.allSettings
            onPageRequested: name => root.page = name
        }
    }
    PowerPanel {
        id: powerOptions
        x: 16; y: 56; width: root.width - 32
        visible: root.powerOpen
        focus: root.powerOpen
        Keys.onEscapePressed: root.closePanels()
    }
    MediaCard {
        id: mediaCard
        x: 16; y: 44; width: root.width - 32
        visible: root.showMedia
    }
    MonthCalendar {
        id: calendarPanel
        x: 0; y: 48; width: root.width; height: root.height - y
        today: clock.date
        visible: root.calendarOpen && !root.popup && !root.powerOpen
        focus: root.calendarOpen
        Keys.onEscapePressed: root.closePanels()
    }
    Item {
        id: capsule
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: root.width
        height: 40
        clip: true
        SystemClock { id: clock; precision: root.calendarOpen ? SystemClock.Seconds : SystemClock.Minutes }
        Text {
            id: timeLabel
            visible: !root.popup && !root.searchOpen && !root.clipboardOpen
            x: (root.width - timeLabel.implicitWidth) / 2
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, root.calendarOpen ? "HH:mm:ss" : "HH:mm")
            color: Theme.text; font.pixelSize: Theme.clockSize; font.family: Theme.font
            MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleCalendar() }
        }
    }
    ActionButton {
        id: idleRecording
        visible: Services.recording && !root.revealed && !root.popup
        x: root.width-30; y: 4; width: 24; height: 32; label: "\uf03d"; iconSize: 16; tint: Theme.danger; hint: "Gravação em andamento"
        onTriggered: root.openPage("audio",true)
    }
    ClipboardPanel { id: clipboardPanel; width: root.width; visible: root.clipboardOpen; onCloseRequested: { root.closePanels(); root.hovered=false } }
    NoticeCard { id: noticeCard; width: root.width; visible: root.popup; notice: root.notice }
    SearchPanel { id: searchPanel; width: root.width; visible: root.searchOpen; onCloseRequested: { root.closePanels(); root.hovered=false } }
}
