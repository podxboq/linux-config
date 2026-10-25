import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Tarjeta de sensor: icono y título, valor grande, mínimo/máximo con tendencia
// y la gráfica de historial al fondo. El borde se colorea según `level`.
Item {
    id: tile

    property string icon: ""
    property string title: ""
    property string value: ""
    property string subtitle: ""
    property var history: []
    property int capacity: 60
    property real maxValue: 0
    property real minScale: 1
    property var formatter: function (v) { return Math.round(v).toString() }
    property bool showRange: true
    property color accent: Style.accent
    property string level: "ok"    // ok | warn | alert

    readonly property var stats: computeStats(history)

    implicitHeight: 76

    function computeStats(h) {
        var n = h ? h.length : 0
        if (n === 0)
            return { min: 0, max: 0, trend: "→" }
        var min = h[0]
        var max = h[0]
        for (var i = 1; i < n; i++) {
            min = Math.min(min, h[i])
            max = Math.max(max, h[i])
        }
        var trend = "→"
        var k = Math.min(10, Math.floor(n / 2))
        if (k > 0) {
            var recent = 0
            var before = 0
            for (var j = 0; j < k; j++) {
                recent += h[n - 1 - j]
                before += h[n - 1 - k - j]
            }
            var span = Math.max(max - min, maxValue > 0 ? maxValue * 0.05 : minScale * 0.05)
            var delta = (recent - before) / k
            if (delta > span * 0.25)
                trend = "↗"
            else if (delta < -span * 0.25)
                trend = "↘"
        }
        return { min: min, max: max, trend: trend }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Style.tile
        border.width: tile.level === "ok" ? 1 : 2
        border.color: tile.level === "alert" ? Style.alert
                    : tile.level === "warn" ? Style.warn
                    : Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.6)
    }

    Graph {
        anchors.fill: parent
        anchors.margins: 1
        radius: 7
        plotTop: 0.45
        values: tile.history
        capacity: tile.capacity
        maxValue: tile.maxValue
        minScale: tile.minScale
        lineColor: tile.accent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 7
        anchors.bottomMargin: 6
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Kirigami.Icon {
                source: tile.icon
                isMask: true
                color: tile.accent
                implicitWidth: 14
                implicitHeight: 14
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
            }
            Lbl {
                Layout.fillWidth: true
                text: tile.title
                color: Style.muted
                font.pointSize: 9
            }
            Lbl {
                visible: tile.showRange && tile.history.length > 1
                text: "↓" + tile.formatter(tile.stats.min) + " ↑" + tile.formatter(tile.stats.max) + " " + tile.stats.trend
                color: Style.muted
                font.pointSize: 8
            }
        }

        Lbl {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: tile.value
            font.pointSize: 17
            font.bold: true
        }

        Lbl {
            Layout.fillWidth: true
            visible: tile.subtitle !== ""
            text: tile.subtitle
            color: Style.muted
            font.pointSize: 8
        }
    }
}
