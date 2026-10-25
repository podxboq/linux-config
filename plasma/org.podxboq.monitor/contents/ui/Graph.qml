import QtQuick

// Gráfica de área: las muestras se alinean a la derecha y la escala
// horizontal es fija, de modo que la curva "entra" por ese lado.
Canvas {
    id: graph

    property var values: []
    property int capacity: 60
    property real maxValue: 0    // 0 = escala automática
    property real minScale: 1    // en escala automática, el techo nunca baja de aquí
    property real plotTop: 0     // fracción de la altura donde empieza la zona de dibujo
    property real radius: 0      // esquinas redondeadas del recorte
    property color lineColor: Style.accent

    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var r = radius
        ctx.beginPath()
        ctx.moveTo(r, 0)
        ctx.lineTo(width - r, 0)
        ctx.arcTo(width, 0, width, r, r)
        ctx.lineTo(width, height - r)
        ctx.arcTo(width, height, width - r, height, r)
        ctx.lineTo(r, height)
        ctx.arcTo(0, height, 0, height - r, r)
        ctx.lineTo(0, r)
        ctx.arcTo(0, 0, r, 0, r)
        ctx.closePath()
        ctx.clip()

        var n = values.length
        if (n < 2)
            return
        var top = maxValue > 0 ? maxValue : Math.max(minScale, Math.max.apply(null, values))
        var y0 = height * plotTop
        var plotH = height - y0
        var dx = width / (capacity - 1)
        var x = function (i) { return width - (n - 1 - i) * dx }
        var y = function (v) { return height - 1 - Math.min(v / top, 1) * (plotH - 2) }

        ctx.beginPath()
        ctx.moveTo(x(0), height)
        for (var i = 0; i < n; i++)
            ctx.lineTo(x(i), y(values[i]))
        ctx.lineTo(width, height)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.22)
        ctx.fill()

        ctx.beginPath()
        for (var j = 0; j < n; j++) {
            if (j === 0)
                ctx.moveTo(x(0), y(values[0]))
            else
                ctx.lineTo(x(j), y(values[j]))
        }
        ctx.lineWidth = 1.3
        ctx.strokeStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.85)
        ctx.stroke()
    }
}
