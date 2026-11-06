pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    readonly property string stateDirectory: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/dark-mountain"
    readonly property string name: palette.name
    readonly property string label: palette.label
    readonly property string wallpaperName: palette.wallpaperName
    readonly property string wallpaper: palette.wallpaper
    readonly property color background: palette.background
    readonly property color surface: palette.surface
    readonly property color border: palette.border
    readonly property color text: palette.text
    readonly property color muted: palette.muted
    readonly property color accent: palette.accent
    readonly property color danger: palette.danger
    readonly property var choices: [{name:"mountain", label:"Mountain Dark"}, {name:"mono", label:"Monocromático"}, {name:"red", label:"Mountain Red"}]
    readonly property string font: "JetBrainsMono Nerd Font Mono"
    readonly property string textFont: "Adwaita Sans"
    readonly property int textSize: 13
    readonly property int captionSize: 11
    readonly property int titleSize: 15
    readonly property int clockSize: 16
    readonly property int radius: 6
    readonly property string timezone: "America/Sao_Paulo"
    readonly property int duration: 220
    FileView {
        path: root.stateDirectory + "/theme.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: palette
            property string name: "mountain"
            property string label: "Mountain Dark"
            property string wallpaperName: "mountain"
            property string wallpaper: ""
            property string background: "#000000"
            property string surface: "#101010"
            property string border: "#303030"
            property string text: "#e7e7e7"
            property string muted: "#999999"
            property string accent: "#8f8aac"
            property string danger: "#d45d5d"
        }
    }
}
