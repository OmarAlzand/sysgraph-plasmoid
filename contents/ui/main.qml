// System Graph Gauge: a panel number with a live history graph + breakdown on click.
// Panel (compact): accent bar + optional glyph + the main sensor's value.
// Click (full): accent dot + title + big value, a 60-sample line chart, and a
//               per-sensor breakdown with mini-bars.
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.quickcharts as Charts

PlasmoidItem {
    id: root

    readonly property string mainSensorId: Plasmoid.configuration.mainSensor
    readonly property var detailEntries: Plasmoid.configuration.details
    readonly property color accent: {
        const c = Plasmoid.configuration.accentColor
        return (c && c.length > 0) ? c : Kirigami.Theme.highlightColor
    }
    readonly property real rangeMax: Plasmoid.configuration.rangeMax
    readonly property bool rangeAuto: Plasmoid.configuration.rangeAuto
    readonly property real barMax: Plasmoid.configuration.barMax
    readonly property string glyph: Plasmoid.configuration.glyph
    readonly property string title: Plasmoid.configuration.title

    // theme-adaptive inks (work in light and dark)
    readonly property color inkPrimary: Kirigami.Theme.textColor
    readonly property color inkSecondary: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.72)
    readonly property color inkMuted: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
    readonly property color gridline: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

    Plasmoid.icon: "office-chart-line"
    toolTipMainText: root.title
    toolTipSubText: mainSensor.formattedValue

    preferredRepresentation: compactRepresentation

    Sensors.Sensor {
        id: mainSensor
        sensorId: root.mainSensorId
        updateRateLimit: 1000
    }

    // ---------------- Panel (compact) ----------------
    compactRepresentation: MouseArea {
        id: compact
        // Scale the icon and value to the panel thickness so they read at the
        // same size as the clock/tray instead of a fixed (small) font — matters
        // most on low-resolution panels.
        // panel thickness = the smaller dimension (height on a horizontal panel,
        // width on a vertical one) — robust without depending on enum values
        readonly property real thickness: Math.min(width, height)
        readonly property int valueSize: Math.max(14, Math.round(thickness * 0.5))
        readonly property int glyphSize: Math.round(valueSize * 1.35)

        Layout.minimumWidth: contentRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: contentRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            PC3.Label {
                text: root.glyph
                visible: root.glyph.length > 0
                color: root.accent
                font.pixelSize: compact.glyphSize
                Layout.alignment: Qt.AlignVCenter
            }
            PC3.Label {
                text: mainSensor.formattedValue
                font.pixelSize: compact.valueSize
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ---------------- Popup (full) ----------------
    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 21
        implicitHeight: layout.implicitHeight + Kirigami.Units.gridUnit * 2
        Layout.minimumWidth: Kirigami.Units.gridUnit * 19
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // ---- Header ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing + 2
                Rectangle {
                    width: Kirigami.Units.gridUnit * 0.6
                    height: width; radius: width / 2
                    color: root.accent
                    Layout.alignment: Qt.AlignVCenter
                }
                PC3.Label {
                    text: root.title
                    color: root.inkSecondary
                    font.weight: Font.Medium
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PC3.Label {
                    text: mainSensor.formattedValue
                    color: root.accent
                    font.weight: Font.DemiBold
                    font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.9)
                }
            }

            // ---- Chart ----
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                readonly property real plotH: height - axisLabel0.height

                // gridlines
                Repeater {
                    model: [0, 0.25, 0.5, 0.75, 1]
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width; height: 1
                        color: root.gridline
                        y: Math.round(parent.plotH * modelData)
                    }
                }
                // y-axis extents
                PC3.Label {
                    id: axisTop
                    text: root.rangeAuto ? i18nc("auto-scaled chart axis", "auto") : Math.round(root.rangeMax)
                    color: root.inkMuted; font.pointSize: Kirigami.Theme.smallFont.pointSize
                    anchors.right: parent.right; anchors.top: parent.top; anchors.topMargin: -2
                }
                PC3.Label {
                    id: axisLabel0
                    text: "0"
                    opacity: root.rangeAuto ? 0 : 1
                    color: root.inkMuted; font.pointSize: Kirigami.Theme.smallFont.pointSize
                    anchors.right: parent.right
                    y: parent.plotH - height / 2
                }

                Charts.LineChart {
                    id: chart
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.plotH
                    lineWidth: Math.round(2 * Kirigami.Units.devicePixelRatio)
                    fillOpacity: 0.16
                    colorSource: Charts.SingleValueSource { value: root.accent }
                    valueSources: [ historySource ]
                    yRange { from: 0; to: root.rangeMax; automatic: root.rangeAuto }

                    Charts.SingleValueSource {
                        id: liveValue
                        value: mainSensor.value !== undefined ? mainSensor.value : 0
                    }
                    Charts.HistoryProxySource {
                        id: historySource
                        source: liveValue
                        maximumHistory: 60
                        interval: 1000
                        fillMode: Charts.HistoryProxySource.FillFromStart
                    }
                }
                PC3.Label {
                    text: i18n("last 60 s")
                    color: root.inkMuted; font.pointSize: Kirigami.Theme.smallFont.pointSize
                    anchors.left: parent.left; anchors.bottom: parent.bottom
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: root.gridline }

            // ---- Breakdown ----
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing + 3
                columnSpacing: Kirigami.Units.gridUnit

                Repeater {
                    model: root.detailEntries
                    delegate: ColumnLayout {
                        required property var modelData
                        readonly property var parts: String(modelData).split("|")
                        readonly property bool showBar: root.barMax > 0 && parts.length > 2 && parts[2] === "1"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            PC3.Label {
                                text: parts.length > 1 && parts[1].length > 0 ? parts[1] : detailSensor.name
                                color: root.inkSecondary
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            PC3.Label {
                                text: detailSensor.formattedValue
                                color: root.inkPrimary
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.weight: Font.DemiBold
                            }
                        }
                        Rectangle {
                            visible: parent.showBar
                            Layout.fillWidth: true
                            height: Math.round(3 * Kirigami.Units.devicePixelRatio)
                            radius: height / 2
                            color: root.gridline
                            Rectangle {
                                width: Math.max(0, Math.min(1, (detailSensor.value || 0) / root.barMax)) * parent.width
                                height: parent.height; radius: parent.radius
                                color: root.accent
                            }
                        }
                        Sensors.Sensor {
                            id: detailSensor
                            sensorId: parts[0]
                            updateRateLimit: 1000
                        }
                    }
                }
            }
        }
    }
}
