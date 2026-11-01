import QtQuick
import QtQuick.Layouts

// Tarjeta centrada: un valor grande y una línea pequeña debajo (uptime).
Rectangle {
    property string value: ""
    property string subtitle: ""

    implicitHeight: 74
    radius: 8
    color: Style.tile
    border.width: 1
    border.color: Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.6)

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 16
        spacing: 0

        Lbl {
            Layout.alignment: Qt.AlignHCenter
            text: value
            color: Style.accent
            font.pointSize: 28
            font.bold: true
        }
        Lbl {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: subtitle
            color: Style.muted
            font.pointSize: 9
        }
    }
}
