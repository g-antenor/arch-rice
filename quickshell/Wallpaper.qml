import QtQuick
import Quickshell
import Quickshell.Wayland
PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "dark-mountain-wallpaper"
    mask: Region {}
    Image {
        anchors.fill: parent
        source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
}
