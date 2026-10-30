import QtQuick
import QtQuick.Shapes

// Circular ring gauge. Exposes `hovered` so callers can show a tooltip.
Item {
    id: root

    property real value: 0 // 0..1
    property color color: "#89b4fa"
    property color trackColor: "#30ffffff"
    property real thickness: 4
    readonly property bool hovered: hover.hovered

    implicitWidth: 22
    implicitHeight: 22

    property real shownValue: Math.max(0, Math.min(1, value))
    Behavior on shownValue { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    HoverHandler { id: hover }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: -90
                sweepAngle: 360 * root.shownValue
            }
        }
    }
}
