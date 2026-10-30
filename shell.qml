import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

ShellRoot {
    id: shell

    // ---- Memory (from /proc/meminfo) ----
    property real memUsage: 0

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0);
            if (total > 0) shell.memUsage = 1 - avail / total;
        }
    }

    Timer {
        interval: 2000
        running: shell.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: meminfo.reload()
    }

    // ---- Battery (UPower) ----
    readonly property var battery: UPower.displayDevice
    readonly property real batteryLevel: battery?.ready ? battery.percentage : 0
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.FullyCharged

    // UPower's estimate in seconds; 0 while it's still calculating or when full.
    readonly property string batteryEstimate: {
        const secs = battery?.state === UPowerDeviceState.Charging ? battery.timeToFull
                   : battery?.state === UPowerDeviceState.Discharging ? battery.timeToEmpty
                   : 0;
        if (!secs) return "";
        const h = Math.floor(secs / 3600);
        const m = Math.round(secs % 3600 / 60);
        const t = h > 0 ? h + "h " + m + "m" : m + "m";
        return battery.state === UPowerDeviceState.Charging ? t + " to full" : t + " left";
    }

    // ---- Visibility (toggle with: qs -p <dir> ipc call widget toggle) ----
    property bool shown: true

    IpcHandler {
        target: "widget"
        function toggle(): void { shell.shown = !shell.shown; }
        // Not named show/hide: "show" collides with the `qs ipc show` subcommand.
        function open(): void { shell.shown = true; }
        function close(): void { shell.shown = false; }
    }

    // ---- Time ----
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: shell.shown
    }

    // Windows only exist while shown, so nothing renders when hidden.
    LazyLoader {
        active: shell.shown

        Variants {
            model: Quickshell.screens

            PanelWindow {
                id: win
                required property var modelData
                screen: modelData

                // Only anchoring top centers the window horizontally.
                anchors.top: true
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "status-widget"

                color: "transparent"
                implicitWidth: notch.width
                implicitHeight: notch.height

                Item {
                    id: notch

                    // Concave fillet where the notch meets the screen edge,
                    // and the rounded bottom corners.
                    readonly property real fillet: 8
                    readonly property real corner: 14

                    width: row.implicitWidth + 22 + fillet * 2
                    height: row.implicitHeight + 4

                    TapHandler {
                        onTapped: shell.shown = false
                    }

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            id: np
                            readonly property real w: notch.width
                            readonly property real h: notch.height
                            readonly property real f: notch.fillet
                            readonly property real r: notch.corner

                            fillColor: "#000000"
                            strokeColor: "transparent"
                            startX: 0
                            startY: 0

                            PathArc { x: np.f; y: np.f; radiusX: np.f; radiusY: np.f }
                            PathLine { x: np.f; y: np.h - np.r }
                            PathArc { x: np.f + np.r; y: np.h; radiusX: np.r; radiusY: np.r; direction: PathArc.Counterclockwise }
                            PathLine { x: np.w - np.f - np.r; y: np.h }
                            PathArc { x: np.w - np.f; y: np.h - np.r; radiusX: np.r; radiusY: np.r; direction: PathArc.Counterclockwise }
                            PathLine { x: np.w - np.f; y: np.f }
                            PathArc { x: np.w; y: 0; radiusX: np.f; radiusY: np.f }
                            PathLine { x: 0; y: 0 }
                        }
                    }

                    RowLayout {
                        id: row
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 0
                        spacing: 16

                        Gauge {
                            id: memGauge
                            value: shell.memUsage
                            color: shell.memUsage > 0.85 ? "#f38ba8"
                                 : shell.memUsage > 0.65 ? "#fab387"
                                 : "#89b4fa"
                        }

                        Text {
                            id: time
                            Layout.alignment: Qt.AlignVCenter
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: "#cdd6f4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 26
                            font.weight: Font.Bold

                            // Shadow: a less-opacity copy shifted left and down.
                            Text {
                                x: -2
                                y: 2
                                z: -1
                                text: time.text
                                color: time.color
                                font: time.font
                                opacity: 0.3
                            }

                            HoverHandler { id: timeHover }
                        }

                        Gauge {
                            id: batteryGauge
                            value: shell.batteryLevel
                            color: shell.charging ? "#6fe864"
                                 : shell.batteryLevel < 0.2 ? "#f38ba8"
                                 : "#a6e3a1"
                        }
                    }

                    Tooltip {
                        target: memGauge
                        container: notch
                        shown: memGauge.hovered
                        text: Math.round(shell.memUsage * 100) + "%"
                    }

                    Tooltip {
                        target: time
                        container: notch
                        shown: timeHover.hovered
                        text: Qt.formatDateTime(clock.date, "dd/MM/yy")
                    }

                    Tooltip {
                        target: batteryGauge
                        container: notch
                        shown: batteryGauge.hovered
                        text: Math.round(shell.batteryLevel * 100) + "%"
                            + (shell.batteryEstimate ? " · " + shell.batteryEstimate : "")
                    }
                }
            }
        }
    }
}
