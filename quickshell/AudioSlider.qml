import QtQuick
import QtQuick.Controls
Slider {
    id: control
    from: 0; to: 1; implicitHeight: 28
    background: Rectangle {
        x: control.leftPadding; y: (control.height - height) / 2
        width: control.availableWidth; height: 3; radius: 2; color: Theme.border
        Rectangle { width: parent.width * control.visualPosition; height: 3; radius: 2; color: Theme.accent }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: (control.height - height) / 2
        width: 10; height: 10; radius: 5; color: control.enabled ? Theme.accent : Theme.muted
    }
}
