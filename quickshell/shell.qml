import QtQuick
import Quickshell
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                required property var modelData
                Wallpaper { screen: modelData }
                Island { screen: modelData }
                CaptureOverlay { screen: modelData; outputName: modelData.name }
            }
        }
    }
}
