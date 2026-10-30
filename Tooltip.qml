import Quickshell
import QtQuick

// Small tooltip shown just below `container`, horizontally centred on `target`.
PopupWindow {
    id: root

    required property Item target
    required property Item container
    property bool shown: false
    property string text: ""

    // Gap from the target's bottom edge down past the container's bottom edge.
    // Referencing `shown` re-evaluates it each time the tooltip opens.
    readonly property real offset: shown
        ? container.height - target.mapToItem(container, 0, target.height).y + 6
        : 0

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    visible: shown
    color: "transparent"
    implicitWidth: tip.width
    implicitHeight: tip.height + offset

    Rectangle {
        id: tip
        y: root.offset
        width: label.implicitWidth + 16
        height: label.implicitHeight + 8
        radius: 8
        color: "#000000"

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: "#cdd6f4"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }
    }
}
