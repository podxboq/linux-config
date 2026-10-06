// Widgets de monitorización (sustituyen a conky) en el escritorio del portátil.
// Usan ksystemstats a través del widget nativo «Monitor del sistema».
//
// Ejecutar con:
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat monitor-widgets.js)"
//   systemctl --user restart plasma-plasmashell   # para que carguen la configuración
//
// Los identificadores de sensores se pueden consultar con `kstatsviewer --list`.

var IFACE   = "wlo1";
var BATTERY = "power/123456789";

var widgets = [
    {
        title: "CPU",
        face: "org.kde.ksysguard.linechart",
        high: ["cpu/all/usage"],
        total: [],
        low: ["cpu/all/averageTemperature", "cpu/all/averageFrequency"],
        faceConfig: { rangeAutoY: false, rangeFromY: 0, rangeToY: 100, lineChartSmooth: true, showLegend: false }
    },
    {
        title: "Memoria",
        face: "org.kde.ksysguard.piechart",
        high: ["memory/physical/used"],
        total: ["memory/physical/usedPercent"],
        low: ["memory/physical/total"],
        faceConfig: { rangeAuto: true, showLegend: false }
    },
    {
        title: "Disco",
        face: "org.kde.ksysguard.piechart",
        high: ["disk/all/used"],
        total: ["disk/all/usedPercent"],
        low: ["disk/all/free", "disk/all/read", "disk/all/write"],
        faceConfig: { rangeAuto: true, showLegend: false }
    },
    {
        title: "Wi-Fi",
        face: "org.kde.ksysguard.linechart",
        high: ["network/" + IFACE + "/download", "network/" + IFACE + "/upload"],
        total: [],
        low: ["network/" + IFACE + "/network", "network/" + IFACE + "/signal"],
        labels: { ["network/" + IFACE + "/network"]: "Red", ["network/" + IFACE + "/signal"]: "Señal" },
        faceConfig: { rangeAutoY: true, lineChartSmooth: true, showLegend: true }
    },
    {
        title: "Batería",
        face: "org.kde.ksysguard.piechart",
        high: [BATTERY + "/chargePercentage"],
        total: [BATTERY + "/chargePercentage"],
        low: [BATTERY + "/chargeRate", BATTERY + "/health"],
        labels: { [BATTERY + "/chargePercentage"]: "Carga", [BATTERY + "/chargeRate"]: "Consumo", [BATTERY + "/health"]: "Salud" },
        faceConfig: { rangeAuto: false, rangeFrom: 0, rangeTo: 100, showLegend: false }
    }
];

// Fila en la parte inferior de la pantalla del portátil (1920x1200).
// addWidget recibe el tamaño del contenido; Folder View añade 28 px de marco,
// así que cada widget ocupa 192x224 en el escritorio.
//
// Disposición completa del escritorio (Containments][1] en
// ~/.config/plasma-org.kde.plasma.desktop-appletsrc), guardada el 2026-10-06.
// Los números de applet dependen de la instalación:
//   72 flipclock, 73 claudeusage, 74 claudemeter, 76 klaudemonitor,
//   83 CPU, 84 Memoria, 85 Disco, 86 Wi-Fi, 87 Batería.
//
//   ItemGeometries-1920x1200=Applet-76:0,496,672,640,0;Applet-73:0,0,384,496,0;Applet-74:384,0,288,496,0;Applet-83:672,912,192,224,0;Applet-84:864,912,192,224,0;Applet-85:1056,912,192,224,0;Applet-86:1248,912,192,224,0;Applet-72:1680,0,224,208,0;Applet-87:1440,912,192,224,0;
//
// Folder View recoloca los widgets que se solapan con otros, así que si quedan
// mal colocados conviene restaurar esa línea (y ItemGeometriesHorizontal) con
// plasmashell parado.
var X0 = 686, Y = 980, W = 164, H = 196, GAP = 28;

var desk = desktops().filter(function (d) { return d.screen === 0; })[0];

// Reutilizar los widgets de una ejecución anterior (por título) para que el
// script sea idempotente sin que Plasma recoloque el escritorio.
var existing = {};
desk.widgets("org.kde.plasma.systemmonitor").forEach(function (w) {
    w.currentConfigGroup = ["Appearance"];
    existing[w.readConfig("title", "")] = w;
});

widgets.forEach(function (s, i) {
    var w = existing[s.title] ||
            desk.addWidget("org.kde.plasma.systemmonitor", X0 + i * (W + GAP), Y, W, H);

    w.currentConfigGroup = ["Appearance"];
    w.writeConfig("chartFace", s.face);
    w.writeConfig("title", s.title);
    w.writeConfig("showTitle", true);

    w.currentConfigGroup = ["Sensors"];
    w.writeConfig("highPrioritySensorIds", JSON.stringify(s.high));
    w.writeConfig("totalSensors", JSON.stringify(s.total));
    w.writeConfig("lowPrioritySensorIds", JSON.stringify(s.low));

    w.currentConfigGroup = ["SensorLabels"];
    for (var id in s.labels || {})
        w.writeConfig(id, s.labels[id]);

    w.currentConfigGroup = ["FaceConfig"];
    for (var k in s.faceConfig)
        w.writeConfig(k, s.faceConfig[k]);

    w.reloadConfig();
});
