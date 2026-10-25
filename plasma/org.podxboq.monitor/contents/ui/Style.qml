pragma Singleton
import QtQuick

// Paleta podxboq oscura (verde salvia), la misma de conky/conkyrc
QtObject {
    readonly property string font: "Source Sans 3"

    readonly property color tile: Qt.rgba(0x26 / 255, 0x2C / 255, 0x28 / 255, 0.90)
    readonly property color text: "#E6EBE7"
    readonly property color accent: "#8CC09D"
    readonly property color muted: "#A5ACA8"
    readonly property color dim: "#4E5852"
    readonly property color good: "#9BD3A8"
    readonly property color alert: "#E07A6E"
    readonly property color warn: "#D9B46A"

    readonly property color downLine: "#9BD3A8"
    readonly property color upLine: "#7FA8CC"
}
