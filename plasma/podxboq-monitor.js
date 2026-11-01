// Coloca el widget «podxboq Monitor» en el escritorio del portátil, alineado
// a la derecha y centrado en vertical. Es idempotente: si ya existe lo
// recoloca (lo quita y lo vuelve a añadir).
//
// Requiere el plasmoide instalado (enlace en ~/.local/share/plasma/plasmoids):
//   ln -s "$PWD/org.podxboq.monitor" ~/.local/share/plasma/plasmoids/org.podxboq.monitor
//
// Ejecutar con:
//   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat podxboq-monitor.js)"
//
// W y H son el tamaño natural de la vista (Tiles.qml con 320 px de ancho).
// Si se añaden o quitan tarjetas hay que recalcular H con tests/preview.qml.
//
// La tarjeta de agenda muestra los calendarios marcados para el plugin
// «Eventos del calendario» de Plasma (ids de colección de Akonadi: 109 GESACA,
// 129 Personal). Para marcarlos:
//   kwriteconfig6 --file plasmashellrc --group PIMEventsPlugin --key calendars 109,129

var PLUGIN = "org.podxboq.monitor";
var W = 320, H = 794, MARGIN = 16;

var desk = desktops().filter(function (d) { return d.screen === 0; })[0];
var screen = screenGeometry(desk.screen);

desk.widgets(PLUGIN).forEach(function (w) { w.remove(); });

desk.addWidget(PLUGIN,
               screen.width - W - MARGIN,
               Math.round((screen.height - H) / 2),
               W, H);
