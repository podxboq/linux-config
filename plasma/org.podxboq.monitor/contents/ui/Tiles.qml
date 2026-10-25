import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Vista del widget: cuadrícula de tarjetas. No lee sensores; recibe los datos
// por propiedades, así se puede renderizar fuera de Plasma (tests/preview.qml).
Item {
    id: view

    property var now: new Date()
    property string kernel: ""
    property real uptime: 0

    property real cpu: 0
    property real cpuTemp: 0
    property real memUsed: 0
    property real memTotal: 0
    property real memPct: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real diskPct: 0
    property string netName: ""
    property real netSignal: 0
    property real netDown: 0
    property real netUp: 0
    property string netIp: ""
    property real battery: 0
    property string batteryStatus: ""
    property real keyboard: -1    // -1 = no disponible
    property real mouse: -1
    property var topCpu: []
    property var topMem: []

    property var cpuHist: []
    property var tempHist: []
    property var memHist: []
    property var diskHist: []
    property var downHist: []
    property var upHist: []
    property int historySize: 60

    implicitWidth: 320
    implicitHeight: grid.implicitHeight

    function fmtNumber(v, decimals) {
        return Number(v).toLocaleString(Qt.locale(), "f", decimals)
    }

    function fmtBytes(bytes, compact) {
        var units = ["B", "KiB", "MiB", "GiB", "TiB"]
        var i = 0
        var v = Number(bytes) || 0
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024
            i++
        }
        return fmtNumber(v, i === 0 ? 0 : 1) + (compact ? "" : " " + units[i])
    }

    function fmtRate(bytes) {
        return fmtBytes(bytes, false) + "/s"
    }

    function fmtUptime(seconds) {
        var s = Math.floor(Number(seconds) || 0)
        var d = Math.floor(s / 86400)
        var h = Math.floor(s % 86400 / 3600)
        var m = Math.floor(s % 3600 / 60)
        return (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m"
    }

    // Uso: ámbar a partir del 70 %, rojo a partir del 90 %
    function loadLevel(percent) {
        return percent >= 90 ? "alert" : percent >= 70 ? "warn" : "ok"
    }

    function tempLevel(celsius) {
        return celsius >= 90 ? "alert" : celsius >= 75 ? "warn" : "ok"
    }

    function chargeLevel(percent) {
        return percent <= 15 ? "alert" : percent <= 30 ? "warn" : "ok"
    }

    function batteryIcon(percent) {
        return "battery-" + String(Math.round(percent / 10) * 10).padStart(3, "0")
    }

    readonly property string peripheralsLevel: {
        var worst = "ok"
        var values = [keyboard, mouse]
        for (var i = 0; i < values.length; i++) {
            if (values[i] < 0)
                continue
            var l = chargeLevel(values[i])
            if (l === "alert")
                return "alert"
            if (l === "warn")
                worst = "warn"
        }
        return worst
    }

    function signalLevel(percent) {
        return percent < 25 ? "alert" : percent < 45 ? "warn" : "ok"
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 2
        columnSpacing: 6
        rowSpacing: 6

        // Reloj y uptime
        Banner {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            value: Qt.formatDateTime(view.now, "HH:mm")
            subtitle: Qt.locale().toString(view.now, "ddd, d MMM yyyy")
        }
        Banner {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            value: view.fmtUptime(view.uptime)
            subtitle: "Uptime · " + view.kernel.replace(/^Linux /, "").split("-")[0]
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Qt.resolvedUrl("../icons/cpu.svg")
            title: "CPU"
            value: Math.round(view.cpu) + " %"
            history: view.cpuHist
            capacity: view.historySize
            maxValue: 100
            level: view.loadLevel(view.cpu)
        }
        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "temperature-normal"
            title: "Temperatura"
            value: Math.round(view.cpuTemp) + " °C"
            history: view.tempHist
            capacity: view.historySize
            minScale: 60
            level: view.tempLevel(view.cpuTemp)
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Qt.resolvedUrl("../icons/memory.svg")
            title: "Memoria"
            value: view.fmtBytes(view.memUsed)
            subtitle: Math.round(view.memPct) + " % de " + view.fmtBytes(view.memTotal)
            history: view.memHist
            capacity: view.historySize
            maxValue: 100
            showRange: false
            level: view.loadLevel(view.memPct)
        }
        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "drive-harddisk"
            title: "Disco"
            value: view.fmtBytes(view.diskUsed)
            subtitle: Math.round(view.diskPct) + " % de " + view.fmtBytes(view.diskTotal)
            history: view.diskHist
            capacity: view.historySize
            minScale: 1048576
            showRange: false
            level: view.loadLevel(view.diskPct)
        }

        Tile {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: 52
            icon: "network-wireless"
            title: view.netName
            value: Math.round(view.netSignal) + " %"
            level: view.signalLevel(view.netSignal)
            Lbl {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: view.netIp
                color: Style.muted
                font.pointSize: 9
            }
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "go-down"
            title: "Descarga"
            value: view.fmtRate(view.netDown)
            history: view.downHist
            capacity: view.historySize
            minScale: 102400
            showRange: false
            accent: Style.downLine
        }
        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "go-up"
            title: "Subida"
            value: view.fmtRate(view.netUp)
            history: view.upHist
            capacity: view.historySize
            minScale: 102400
            showRange: false
            accent: Style.upLine
        }

        Tile {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: view.batteryIcon(view.battery)
            title: "Batería"
            value: Math.round(view.battery) + " %"
            subtitle: view.batteryStatus
            level: view.chargeLevel(view.battery)
        }
        // Teclado y ratón (Logitech): UPower solo recibe niveles aproximados
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: 76
            radius: 8
            color: Style.tile
            border.width: view.peripheralsLevel === "ok" ? 1 : 2
            border.color: view.peripheralsLevel === "alert" ? Style.alert
                        : view.peripheralsLevel === "warn" ? Style.warn
                        : Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.6)

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 3

                Item { Layout.fillHeight: true }
                Repeater {
                    model: [
                        { icon: "input-keyboard", name: "Teclado", value: view.keyboard },
                        { icon: "input-mouse", name: "Ratón", value: view.mouse }
                    ]
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 5
                        visible: modelData.value >= 0

                        Kirigami.Icon {
                            source: modelData.icon
                            isMask: true
                            color: Style.accent
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                        }
                        Lbl { Layout.fillWidth: true; text: modelData.name; color: Style.muted; font.pointSize: 9 }
                        Lbl {
                            text: Math.round(modelData.value) + " %"
                            color: view.chargeLevel(modelData.value) === "alert" ? Style.alert
                                 : view.chargeLevel(modelData.value) === "warn" ? Style.warn
                                 : Style.text
                            font.pointSize: 11
                            font.bold: true
                        }
                    }
                }
                Lbl {
                    visible: view.keyboard < 0 && view.mouse < 0
                    Layout.fillWidth: true
                    text: "Sin periféricos"
                    color: Style.muted
                    font.pointSize: 9
                }
                Item { Layout.fillHeight: true }
            }
        }

        // Procesos
        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            implicitHeight: procs.implicitHeight + 16
            radius: 8
            color: Style.tile
            border.width: 1
            border.color: Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.6)

            RowLayout {
                id: procs
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 12

                Repeater {
                    model: [
                        { title: "Procesos · CPU", list: view.topCpu },
                        { title: "Procesos · MEM", list: view.topMem }
                    ]
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 1

                        Lbl { text: modelData.title; color: Style.accent; font.pointSize: 8; font.weight: Font.DemiBold }
                        Repeater {
                            model: modelData.list
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Lbl { Layout.fillWidth: true; text: modelData.name; color: Style.muted; font.pointSize: 9 }
                                Lbl { text: view.fmtNumber(modelData.value, 1) + "%"; color: Style.muted; font.pointSize: 9 }
                            }
                        }
                    }
                }
            }
        }
    }
}
