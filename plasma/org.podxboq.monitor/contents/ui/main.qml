import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.workspace.calendar as PimCalendar

PlasmoidItem {
    id: root

    // Dispositivos concretos de este equipo (ver `kstatsviewer --list`)
    readonly property string netIf: "wlo1"
    readonly property string disk: "nvme0n1"
    readonly property string battery: "123456789"
    readonly property string keyboardId: "01-51-88-ed"    // Logitech K540/K545
    readonly property string mouseId: "33-e5-e2-23"       // Logitech Wireless Mouse

    readonly property int historySize: 60
    readonly property int agendaDays: 15

    property string kernel: ""
    property var topCpu: []
    property var topMem: []
    property var agenda: []
    property var agendaStart: new Date()
    property var cpuHist: []
    property var tempHist: []
    property var memHist: []
    property var diskHist: []
    property var downHist: []
    property var upHist: []

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Conserva solo las últimas `historySize` muestras
    function push(hist, value) {
        return hist.concat(Number(value) || 0).slice(-historySize)
    }

    function num(sensor) {
        return Number(sensor.value) || 0
    }

    // -1 si el dispositivo no está conectado (el sensor no existe o no tiene valor)
    function optionalPercent(sensor) {
        var v = sensor.value
        return v === undefined || v === null || isNaN(Number(v)) ? -1 : Number(v)
    }

    function batteryStatus() {
        var rate = num(sBatRate)
        if (rate > 0.5)
            return "Cargando"
        if (rate < -0.5)
            return "Descargando"
        return num(sBat) >= 99 ? "Completa" : "En reposo"
    }

    function parseTop(text) {
        var out = []
        var lines = String(text).split("\n")
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].trim().match(/^(.*\S)\s+([\d.,]+)$/)
            if (m)
                out.push({ name: m[1], value: Number(m[2].replace(",", ".")) })
        }
        return out
    }

    Sensors.Sensor { id: sCpu; sensorId: "cpu/all/usage" }
    Sensors.Sensor { id: sCpuTemp; sensorId: "cpu/all/averageTemperature" }
    Sensors.Sensor { id: sMemUsed; sensorId: "memory/physical/used" }
    Sensors.Sensor { id: sMemTotal; sensorId: "memory/physical/total" }
    Sensors.Sensor { id: sMemPct; sensorId: "memory/physical/usedPercent" }
    Sensors.Sensor { id: sDiskUsed; sensorId: "disk/all/used" }
    Sensors.Sensor { id: sDiskTotal; sensorId: "disk/all/total" }
    Sensors.Sensor { id: sDiskPct; sensorId: "disk/all/usedPercent" }
    Sensors.Sensor { id: sDiskRead; sensorId: "disk/" + root.disk + "/read" }
    Sensors.Sensor { id: sDiskWrite; sensorId: "disk/" + root.disk + "/write" }
    Sensors.Sensor { id: sNetName; sensorId: "network/" + root.netIf + "/network" }
    Sensors.Sensor { id: sNetSignal; sensorId: "network/" + root.netIf + "/signal" }
    Sensors.Sensor { id: sNetDown; sensorId: "network/" + root.netIf + "/download" }
    Sensors.Sensor { id: sNetUp; sensorId: "network/" + root.netIf + "/upload" }
    Sensors.Sensor { id: sNetIp; sensorId: "network/" + root.netIf + "/ipv4address" }
    Sensors.Sensor { id: sBat; sensorId: "power/" + root.battery + "/chargePercentage" }
    Sensors.Sensor { id: sBatRate; sensorId: "power/" + root.battery + "/chargeRate" }
    Sensors.Sensor { id: sKeyboard; sensorId: "power/" + root.keyboardId + "/chargePercentage" }
    Sensors.Sensor { id: sMouse; sensorId: "power/" + root.mouseId + "/chargePercentage" }
    Sensors.Sensor { id: sUptime; sensorId: "os/system/uptime" }

    // Agenda: eventos de los calendarios marcados en el plugin «Eventos del
    // calendario» de Plasma (pimevents), que lee Akonadi (Kontact). Solo se
    // muestran los marcados en ~/.config/plasmashellrc:
    //   [PIMEventsPlugin]
    //   calendars=109,129      # ids de colección de Akonadi (GESACA, Personal)
    // Cada Calendar cubre una cuadrícula de 42 días del mes que muestra; se usan
    // dos para que los 15 días queden dentro aunque crucen de mes.
    PimCalendar.EventPluginsManager {
        id: pim
        enabledPlugins: ["pimevents"]
    }
    PimCalendar.Calendar {
        id: calStart
        days: 7
        weeks: 6
        today: root.agendaStart
        displayedDate: root.agendaStart
        Component.onCompleted: daysModel.setPluginsManager(pim)
    }
    PimCalendar.Calendar {
        id: calEnd
        days: 7
        weeks: 6
        today: root.agendaStart
        displayedDate: new Date(root.agendaStart.getFullYear(), root.agendaStart.getMonth(),
                                root.agendaStart.getDate() + root.agendaDays - 1)
        Component.onCompleted: daysModel.setPluginsManager(pim)
    }

    function eventsOf(date) {
        var list = calStart.daysModel.eventsForDate(date)
        return list.length > 0 ? list : calEnd.daysModel.eventsForDate(date)
    }

    function buildAgenda() {
        var start = root.agendaStart
        var out = []
        for (var i = 0; i < agendaDays; i++) {
            var date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            var evs = []
            var list = eventsOf(date)
            for (var j = 0; j < list.length; j++) {
                var e = list[j]
                evs.push({
                    title: String(e.title),
                    time: e.isAllDay ? "" : Qt.formatTime(e.startDateTime, "HH:mm"),
                    color: String(e.eventColor),
                    start: e.isAllDay ? 0 : e.startDateTime.getTime(),
                    end: e.isAllDay ? 0 : e.endDateTime.getTime()
                })
            }
            // Primero los de todo el día, luego por hora
            evs.sort(function (a, b) { return a.start - b.start })
            out.push({ date: date, events: evs })
        }
        root.agenda = out
    }

    // Los datos llegan por lotes: se reconstruye una vez pasada la ráfaga
    Timer {
        id: agendaRefresh
        interval: 300
        onTriggered: root.buildAgenda()
    }
    Connections {
        target: calStart.daysModel
        function onAgendaUpdated() { agendaRefresh.restart() }
    }
    Connections {
        target: calEnd.daysModel
        function onAgendaUpdated() { agendaRefresh.restart() }
    }
    Connections {
        target: pim
        function onEventModified() { agendaRefresh.restart() }
        function onEventRemoved() { agendaRefresh.restart() }
    }

    // Al cambiar de día, la agenda arranca en el nuevo día
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            if (now.toDateString() !== root.agendaStart.toDateString())
                root.agendaStart = now
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuHist = root.push(root.cpuHist, root.num(sCpu))
            root.tempHist = root.push(root.tempHist, root.num(sCpuTemp))
            root.memHist = root.push(root.memHist, root.num(sMemPct))
            root.diskHist = root.push(root.diskHist, root.num(sDiskRead) + root.num(sDiskWrite))
            root.downHist = root.push(root.downHist, root.num(sNetDown))
            root.upHist = root.push(root.upHist, root.num(sNetUp))
        }
    }

    // top muestra el uso instantáneo de CPU solo desde su segunda muestra
    readonly property string cmdTopCpu:
        "top -b -n 2 -d 0.5 -o %CPU -w 200 | awk '/^top -/{n++} n==2 && $1 ~ /^[0-9]+$/ && $NF!=\"top\"{print $NF\" \"$9; c++} c==3{exit}'"
    readonly property string cmdTopMem: "ps -eo comm=,pmem= --sort=-pmem | head -n 3"

    P5Support.DataSource {
        engine: "executable"
        connectedSources: [root.cmdTopCpu, root.cmdTopMem]
        interval: 5000
        onNewData: (source, data) => {
            if (source === root.cmdTopCpu)
                root.topCpu = root.parseTop(data.stdout)
            else if (source === root.cmdTopMem)
                root.topMem = root.parseTop(data.stdout)
        }
    }

    P5Support.DataSource {
        engine: "executable"
        connectedSources: ["uname -sr"]
        interval: 0
        onNewData: (source, data) => root.kernel = String(data.stdout).trim()
    }

    fullRepresentation: Tiles {
        Layout.minimumWidth: 260
        Layout.preferredWidth: 320

        kernel: root.kernel
        uptime: root.num(sUptime)
        cpu: root.num(sCpu)
        cpuTemp: root.num(sCpuTemp)
        memUsed: root.num(sMemUsed)
        memTotal: root.num(sMemTotal)
        memPct: root.num(sMemPct)
        diskUsed: root.num(sDiskUsed)
        diskTotal: root.num(sDiskTotal)
        diskPct: root.num(sDiskPct)
        netName: String(sNetName.value || "")
        netSignal: root.num(sNetSignal)
        netDown: root.num(sNetDown)
        netUp: root.num(sNetUp)
        netIp: String(sNetIp.value || "")
        battery: root.num(sBat)
        batteryStatus: root.batteryStatus()
        keyboard: root.optionalPercent(sKeyboard)
        mouse: root.optionalPercent(sMouse)
        topCpu: root.topCpu
        topMem: root.topMem
        agenda: root.agenda
        cpuHist: root.cpuHist
        tempHist: root.tempHist
        memHist: root.memHist
        diskHist: root.diskHist
        downHist: root.downHist
        upHist: root.upHist
        historySize: root.historySize
    }
}
