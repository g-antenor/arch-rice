import QtQuick
Item {
    id: root
    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    property date selectedDate: today
    readonly property int firstWeekday: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()
    readonly property string title: Qt.locale("pt_BR").toString(new Date(year, month, 1), "MMMM yyyy")
    function sameDay(a,b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    function reset() { year = today.getFullYear(); month = today.getMonth(); selectedDate = today }
    function navigate(offset) { const date = new Date(year, month + offset, 1); year = date.getFullYear(); month = date.getMonth(); selectedDate = date }
    ActionButton { x: 16; y: 6; label: "\uf104"; hint: "Mês anterior"; onTriggered: root.navigate(-1) }
    Text { anchors.horizontalCenter: parent.horizontalCenter; y: 12; text: root.title; color: Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
    ActionButton { anchors.right: parent.right; anchors.rightMargin: 16; y: 6; label: "\uf105"; hint: "Próximo mês"; onTriggered: root.navigate(1) }
    Row {
        x: 16; y: 46
        Repeater {
            model: ["S", "T", "Q", "Q", "S", "S", "D"]
            delegate: Text { required property string modelData; width: (root.width - 32)/7; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.captionSize }
        }
    }
    Grid {
        x: 16; y: 72; columns: 7
        Repeater {
            model: 42
            delegate: Rectangle {
                id: cell
                required property int index
                readonly property int day: index - root.firstWeekday + 1
                readonly property bool valid: day > 0 && day <= root.days
                readonly property date date: new Date(root.year, root.month, day)
                readonly property bool isToday: valid && root.sameDay(date, root.today)
                width: (root.width - 32)/7; height: 32; radius: Theme.radius
                color: isToday ? Theme.accent : "transparent"
                border.width: valid && root.sameDay(date, root.selectedDate) ? 1 : 0; border.color: Theme.accent
                Text { anchors.centerIn: parent; text: cell.valid ? cell.day : ""; color: cell.isToday ? Theme.background : Theme.text; font.family: Theme.textFont; font.pixelSize: Theme.textSize }
                MouseArea { anchors.fill: parent; enabled: cell.valid; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedDate = cell.date }
            }
        }
    }
    Text { x: 16; y: 282; width: parent.width - 32; text: Qt.locale("pt_BR").toString(root.selectedDate, "dddd, dd 'de' MMMM"); elide: Text.ElideRight; color: Theme.muted; font.family: Theme.textFont; font.pixelSize: Theme.captionSize; horizontalAlignment: Text.AlignHCenter }
}
