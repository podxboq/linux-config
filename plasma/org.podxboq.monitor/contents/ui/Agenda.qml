import QtQuick
import QtQuick.Controls as QQC2

// Tarjeta de agenda: una fila por día, también los que no tienen eventos.
// Recibe `days` = [{ date, events: [{ title, time, color, start, end }] }]
// (time vacío si el evento dura todo el día; start y end en ms) y se desplaza
// con la rueda si no caben todos. Los eventos con hora se pintan en rojo desde
// 15 minutos antes de empezar y en gris una vez terminados.
Rectangle {
    id: card

    property var days: []
    property real nowMs: Date.now()
    readonly property int soonMs: 15 * 60 * 1000

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: card.nowMs = Date.now()
    }

    // "soon" | "done" | "normal"; los de todo el día no cambian de estado
    function eventState(ev) {
        if (ev.time === "")
            return "normal"
        if (card.nowMs >= ev.end)
            return "done"
        return card.nowMs >= ev.start - soonMs && card.nowMs < ev.start ? "soon" : "normal"
    }

    radius: 8
    color: Style.tile
    border.width: 1
    border.color: Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.6)

    function dayLabel(date) {
        var l = Qt.locale().toString(date, "ddd d")
        return date.getDate() === 1 ? Qt.locale().toString(date, "d MMM") : l
    }

    function isToday(date) {
        var n = new Date()
        return date.getFullYear() === n.getFullYear() && date.getMonth() === n.getMonth()
            && date.getDate() === n.getDate()
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 6
        anchors.leftMargin: 10
        anchors.rightMargin: 4
        clip: true
        model: card.days
        boundsBehavior: Flickable.StopAtBounds
        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            // Fina y sin botones, para que no pese en la tarjeta
            policy: QQC2.ScrollBar.AsNeeded
            implicitWidth: 4
            padding: 0
            background: null
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Style.muted
                opacity: 0.55
            }
        }

        delegate: Item {
            id: row
            required property var modelData
            readonly property bool today: card.isToday(modelData.date)

            width: ListView.view.width - 8
            implicitHeight: Math.max(events.implicitHeight, 16) + 5

            Lbl {
                id: label
                width: 42
                y: 1
                text: row.today ? "Hoy" : card.dayLabel(row.modelData.date)
                color: row.today ? Style.accent : Style.muted
                font.pointSize: 9
                font.bold: row.today
            }

            Column {
                id: events
                x: 48
                width: parent.width - 48
                spacing: 1

                Lbl {
                    visible: row.modelData.events.length === 0
                    width: parent.width
                    text: "—"
                    color: Style.dim
                    font.pointSize: 9
                }
                Repeater {
                    model: row.modelData.events
                    Row {
                        id: ev
                        required property var modelData
                        readonly property string state: card.eventState(modelData)
                        width: events.width
                        spacing: 4

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            y: 5
                            opacity: ev.state === "done" ? 0.4 : 1
                            // Los colores muy oscuros (GESACA) se pierden sobre la tarjeta
                            color: {
                                var c = Qt.color(ev.modelData.color)
                                return c.hslLightness < 0.4 ? Qt.lighter(c, 2.4) : c
                            }
                        }
                        Lbl {
                            visible: ev.modelData.time !== ""
                            text: ev.modelData.time
                            color: ev.state === "soon" ? Style.alert : Style.muted
                            font.pointSize: 9
                            font.bold: ev.state === "soon"
                        }
                        Lbl {
                            width: ev.width - x
                            text: ev.modelData.title
                            color: ev.state === "soon" ? Style.alert
                                 : ev.state === "done" ? Style.muted : Style.text
                            font.pointSize: 9
                            font.bold: ev.state === "soon"
                        }
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(Style.dim.r, Style.dim.g, Style.dim.b, 0.35)
            }
        }
    }
}
