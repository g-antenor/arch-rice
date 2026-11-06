import QtQuick
Item {
    id: root
    property var notice: null
    readonly property real desiredWidth: Math.max(280,Math.min(560,Math.max(titleMetrics.advanceWidth+36,bodyMetrics.advanceWidth+36,appMetrics.advanceWidth+90)))
    implicitWidth: desiredWidth
    implicitHeight: content.height+28
    TextMetrics { id: titleMetrics; text: root.notice ? root.notice.summary : ""; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; font.bold: true }
    TextMetrics { id: bodyMetrics; text: root.notice ? root.notice.body : ""; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
    TextMetrics { id: appMetrics; text: root.notice ? root.notice.appName : ""; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
    Column {
        id: content; x: 18; y: 14; width: parent.width-36; spacing: 8
        Item { width: parent.width; height: 24
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\uf0f3"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 16 }
            Text { x: 28; width: parent.width-60; anchors.verticalCenter: parent.verticalCenter; text: root.notice ? root.notice.appName : ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.accent; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
            ActionButton { anchors.right: parent.right; height: 24; label: "×"; hint: "Dispensar"; onTriggered: if (root.notice) root.notice.dismiss() }
        }
        Text { width: parent.width; text: root.notice ? root.notice.summary : ""; visible: text.length>0; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; font.bold: true }
        Text { width: parent.width; text: root.notice ? root.notice.body : ""; visible: text.length>0; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 8; elide: Text.ElideRight; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
        Flow { width: parent.width; spacing: 8
            Repeater { model: root.notice ? root.notice.actions.slice(0,3) : []
                delegate: ActionButton { required property var modelData; width: Math.min(content.width,Math.max(80,modelData.text.length*8+24)); label: modelData.text; hint: modelData.text; onTriggered: { const id=root.notice.id; modelData.invoke(); if (Notifications.current && Notifications.current.id===id) Notifications.hide() } }
            }
        }
    }
}
