pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
Singleton {
    id: root
    property bool doNotDisturb: false
    readonly property var items: server.trackedNotifications.values
    property var queue: []
    property var current: null
    readonly property bool showing: current !== null
    function next() {
        popupTimer.stop()
        current = null
        const live = items.map(n => n.id)
        let pending = queue.filter(n => live.includes(n.id))
        if (pending.length) { current = pending.shift(); popupTimer.interval = current.expireTimeout > 0 ? Math.max(1500, Math.min(15000, current.expireTimeout)) : 5000; popupTimer.start() }
        queue = pending
    }
    function hide() { next() }
    function dismissAll() { queue = []; current = null; popupTimer.stop(); for (const n of [...items]) n.dismiss() }
    function validate() {
        const live = items.map(n => n.id)
        if (current && !live.includes(current.id)) next()
    }
    onItemsChanged: validate()
    onDoNotDisturbChanged: { if (doNotDisturb) { queue = []; current = null; popupTimer.stop() } }
    Timer { id: popupTimer; onTriggered: root.next() }
    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true
        onNotification: n => {
            n.tracked = true
            if (root.items.length > 100) root.items[0].dismiss()
            if (root.doNotDisturb || n.lastGeneration) return
            if (root.current && root.current.id === n.id) { popupTimer.restart(); return }
            root.queue = root.queue.filter(item => item.id !== n.id).concat([n])
            Qt.callLater(() => { if (!root.current) root.next() })
        }
    }
}
