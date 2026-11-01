import QtQuick
import QtQuick.Window
import "../contents/ui"

// Renderiza Tiles.qml con datos de prueba y lo guarda en el PNG indicado por
// el último argumento. Uso:
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 tests/preview.qml -- /ruta/out.png
Window {
    id: win
    visible: true
    width: 344
    height: view.implicitHeight + 24
    color: "#5B6B72"

    function agenda() {
        var base = new Date()
        var now = base.getTime()
        var min = 60000
        var sample = {
            0: [{ title: "Reunión de equipo (finalizada)", time: "08:30", color: "#fd9e18", start: now - 150 * min, end: now - 90 * min },
                { title: "Tutoría (empieza en 10 min)", time: "10:00", color: "#364755", start: now + 10 * min, end: now + 70 * min },
                { title: "Clase de la tarde", time: "17:30", color: "#364755", start: now + 300 * min, end: now + 360 * min }],
            1: [{ title: "(ALCC/MCC/16667) Inicio del tema", time: "", color: "#364755", start: 0, end: 0 },
                { title: "Tutoría con estudiantes", time: "17:30", color: "#364755", start: now + 1800 * min, end: now + 1860 * min }],
            4: [{ title: "Cumpleaños familiar", time: "", color: "#fd9e18", start: 0, end: 0 }],
            5: [{ title: "Entrega de actividad", time: "23:59", color: "#364755", start: now + 7000 * min, end: now + 7001 * min }]
        }
        var out = []
        for (var i = 0; i < 15; i++)
            out.push({ date: new Date(base.getFullYear(), base.getMonth(), base.getDate() + i), events: sample[i] || [] })
        return out
    }

    function wave(base, amp, phase) {
        var out = []
        for (var i = 0; i < 60; i++)
            out.push(Math.max(0, base + amp * Math.sin(i / 6 + phase) + amp * 0.3 * Math.sin(i * 1.7)))
        return out
    }

    Tiles {
        id: view
        x: 12
        y: 12
        width: 320

        kernel: "Linux 6.12.108-1-MANJARO"
        uptime: 3900
        cpu: 23
        cpuTemp: 78
        memUsed: 5974233088
        memTotal: 16101281792
        memPct: 37
        diskUsed: 304278634496
        diskTotal: 962958061568
        diskPct: 31.6
        netName: "Fallen_5G"
        netSignal: 68
        netDown: 1572864
        netUp: 51200
        netIp: "192.168.0.35"
        battery: 12
        batteryStatus: "Descargando"
        keyboard: 100
        mouse: 22
        topCpu: [{ name: "plasmashell", value: 7.3 }, { name: "claude", value: 6.6 }, { name: "conky", value: 0.7 }]
        topMem: [{ name: "plasmashell", value: 3.5 }, { name: "claude", value: 2.6 }, { name: "vivaldi-bin", value: 2.4 }]
        agenda: win.agenda()
        cpuHist: win.wave(25, 12, 0)
        tempHist: win.wave(60, 6, 1)
        memHist: win.wave(37, 2, 2)
        diskHist: win.wave(900000, 800000, 3)
        downHist: win.wave(800000, 700000, 4)
        upHist: win.wave(40000, 30000, 5)
    }

    Timer {
        interval: 700
        running: true
        onTriggered: view.grabToImage(function (result) {
            result.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1])
            Qt.quit()
        })
    }
}
