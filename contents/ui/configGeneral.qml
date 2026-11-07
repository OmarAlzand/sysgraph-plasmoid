import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_title: titleField.text
    property alias cfg_glyph: glyphField.text
    property alias cfg_mainSensor: mainField.text
    property alias cfg_accentColor: accentField.text
    property alias cfg_rangeMax: rangeMaxField.value
    property alias cfg_rangeAuto: rangeAutoBox.checked
    property var cfg_details: []

    QQC2.TextField {
        id: titleField
        Kirigami.FormData.label: i18n("Title:")
    }
    QQC2.TextField {
        id: glyphField
        Kirigami.FormData.label: i18n("Panel glyph:")
        placeholderText: i18n("optional icon character")
    }
    QQC2.TextField {
        id: mainField
        Kirigami.FormData.label: i18n("Main sensor id:")
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    }
    RowLayout {
        Kirigami.FormData.label: i18n("Accent colour:")
        QQC2.TextField {
            id: accentField
            placeholderText: "#00a062"
        }
        Rectangle {
            width: Kirigami.Units.gridUnit
            height: width
            radius: 3
            border.width: 1
            border.color: Kirigami.Theme.textColor
            color: accentField.text.length > 0 ? accentField.text : "transparent"
        }
    }
    QQC2.SpinBox {
        id: rangeMaxField
        Kirigami.FormData.label: i18n("Chart maximum:")
        from: 1
        to: 1000000
        editable: true
    }
    QQC2.CheckBox {
        id: rangeAutoBox
        Kirigami.FormData.label: i18n("Auto-scale chart:")
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.Label {
        Kirigami.FormData.label: i18n("Breakdown:")
        text: i18n("One per line, as  sensorId|Label")
        opacity: 0.7
    }
    QQC2.TextArea {
        id: detailsArea
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        wrapMode: TextEdit.NoWrap
        text: (page.cfg_details || []).join("\n")
        onTextChanged: {
            var lines = text.split("\n").filter(function (l) { return l.trim().length > 0 })
            if (lines.join("\n") !== (page.cfg_details || []).join("\n")) {
                page.cfg_details = lines
            }
        }
    }
}
