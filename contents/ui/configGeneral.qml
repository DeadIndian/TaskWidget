import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

Item {
    id: root
    width: 400
    height: 620
    
    property bool tempHideBackground: hideBackground.checked
    property bool tempEnableBlur: enableBlur.checked
    property bool tempTitleAlignmentCenter: titleAlignmentCenter.checked
    property string tempWidgetTitle: widgetTitle.text
    property string tempWidgetColor: widgetColor.text
    property string tempTaskColor: taskColor.text
    property string tempCompletedTaskColor: completedTaskColor.text
    property string tempTaskTextColor: taskTextColor.text
    property string tempCompletedTaskTextColor: completedTaskTextColor.text
    property string tempWidgetTextColor: widgetTextColor.text
    property real tempBackgroundOpacity: backgroundOpacity.value
    property real tempTaskOpacity: taskOpacity.value
    property int tempBlurRadius: blurRadius.value
    property int tempCornerRadius: cornerRadius.value
    property int tempTaskRadius: taskRadius.value
    property int tempTaskHeight: taskHeight.value
    
    property bool hasChanges: false
    
    function loadConfiguration() {
        if (plasmoid && plasmoid.configuration) {
            tempHideBackground = plasmoid.configuration.hideBackground || false
            tempEnableBlur = plasmoid.configuration.enableBlur || false
            tempTitleAlignmentCenter = plasmoid.configuration.titleAlignmentCenter || false
            tempWidgetTitle = plasmoid.configuration.widgetTitle || i18n("Tasks")
            tempWidgetColor = plasmoid.configuration.widgetColor || "#2d3748"
            tempTaskColor = plasmoid.configuration.taskColor || "#5e3a6b"
            tempCompletedTaskColor = plasmoid.configuration.completedTaskColor || "#2f855a"
            tempTaskTextColor = plasmoid.configuration.taskTextColor || "#ffffff"
            tempCompletedTaskTextColor = plasmoid.configuration.completedTaskTextColor || "#cbd5e0"
            tempWidgetTextColor = plasmoid.configuration.widgetTextColor || "#ffffff"
            tempBackgroundOpacity = plasmoid.configuration.backgroundOpacity || 0.95
            tempTaskOpacity = plasmoid.configuration.taskOpacity || 0.95
            tempBlurRadius = plasmoid.configuration.blurRadius || 8
            tempCornerRadius = plasmoid.configuration.cornerRadius || 16
            tempTaskRadius = plasmoid.configuration.taskRadius || 12
            tempTaskHeight = plasmoid.configuration.taskHeight || 32
            
            hideBackgroundCheckBox.checked = tempHideBackground
            enableBlurCheckBox.checked = tempEnableBlur
            titleAlignmentCheckBox.checked = tempTitleAlignmentCenter
            widgetTitleField.text = tempWidgetTitle
            colorPreview.color = tempWidgetColor
            taskColorPreview.color = tempTaskColor
            completedTaskColorPreview.color = tempCompletedTaskColor
            taskTextColorPreview.color = tempTaskTextColor
            completedTaskTextColorPreview.color = tempCompletedTaskTextColor
            backgroundOpacityField.text = tempBackgroundOpacity.toString()
            taskOpacityField.text = tempTaskOpacity.toString()
            blurRadiusField.text = tempBlurRadius.toString()
            cornerRadiusField.text = tempCornerRadius.toString()
            taskRadiusField.text = tempTaskRadius.toString()
            taskHeightField.text = tempTaskHeight.toString()
            
            hasChanges = false
        }
    }
    
    function applyChanges() {
        if (plasmoid && plasmoid.configuration) {
            plasmoid.configuration.hideBackground = tempHideBackground
            plasmoid.configuration.enableBlur = tempEnableBlur
            plasmoid.configuration.titleAlignmentCenter = tempTitleAlignmentCenter
            plasmoid.configuration.widgetTitle = tempWidgetTitle
            plasmoid.configuration.widgetColor = tempWidgetColor
            plasmoid.configuration.taskColor = tempTaskColor
            plasmoid.configuration.completedTaskColor = tempCompletedTaskColor
            plasmoid.configuration.taskTextColor = tempTaskTextColor
            plasmoid.configuration.completedTaskTextColor = tempCompletedTaskTextColor
            plasmoid.configuration.widgetTextColor = tempWidgetTextColor
            plasmoid.configuration.backgroundOpacity = tempBackgroundOpacity
            plasmoid.configuration.taskOpacity = tempTaskOpacity
            plasmoid.configuration.blurRadius = tempBlurRadius
            plasmoid.configuration.cornerRadius = tempCornerRadius
            plasmoid.configuration.taskRadius = tempTaskRadius
            plasmoid.configuration.taskHeight = tempTaskHeight
            
            hasChanges = false
        }
    }
    
    function markAsChanged() {
        hasChanges = true
        applyButton.enabled = true
        resetButton.enabled = true
    }
    
    Component.onCompleted: {
        loadConfiguration()
    }
    ScrollView {
        id: control
        focus: true
        width: root.availableWidth
        height: root.availableHeight
        anchors.margins: 8
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        ScrollBar.vertical: ScrollBar {
            parent: control
            x: control.mirrored ? 0 : control.width - width
            y: control.topPadding
            height: control.availableHeight
        }
        ColumnLayout {
            width: control.availableWidth
            anchors {
                left: control.left
                right: control.right
                top: control.top
            }
            spacing: 10

            PlasmaComponents.Label {
                text: i18n("Task Widget Configuration")
                font.bold: true
                font.pixelSize: 16
                Layout.fillWidth: true
            }

            PlasmaComponents.CheckBox {
                id: hideBackgroundCheckBox
                text: i18n("Hide background")
                checked: tempHideBackground
                onCheckedChanged: {
                    if (checked !== tempHideBackground) {
                        tempHideBackground = checked
                        markAsChanged()
                    }
                }
            }

            PlasmaComponents.CheckBox {
                id: enableBlurCheckBox
                text: i18n("Enable blur")
                checked: tempEnableBlur
                visible: !hideBackgroundCheckBox.checked
                onCheckedChanged: {
                    if (checked !== tempEnableBlur) {
                        tempEnableBlur = checked
                        markAsChanged()
                    }
                }
            }

            PlasmaComponents.Label {
                text: i18n("Title")
                font.pixelSize: 12
            }
            PlasmaComponents.TextField {
                id: widgetTitleField
                Layout.fillWidth: true
                text: tempWidgetTitle
                onTextChanged: {
                    if (text !== tempWidgetTitle) {
                        tempWidgetTitle = text
                        markAsChanged()
                    }
                }
            }

            PlasmaComponents.CheckBox {
                id: titleAlignmentCheckBox
                text: i18n("Center title alignment")
                checked: tempTitleAlignmentCenter
                onCheckedChanged: {
                    if (checked !== tempTitleAlignmentCenter) {
                        tempTitleAlignmentCenter = checked
                        markAsChanged()
                    }
                }
            }

            PlasmaComponents.Label {
                text: i18n("Main color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: colorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempWidgetColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: colorDialog.open()
                }
            }
            ColorDialog {
                id: colorDialog
                title: i18n("Choose Font Color")
                selectedColor: tempWidgetColor
                onAccepted: {
                    tempWidgetColor = selectedColor
                    colorPreview.color = tempWidgetColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Task color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: taskColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempTaskColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: taskColorDialog.open()
                }
            }
            ColorDialog {
                id: taskColorDialog
                title: i18n("Choose Task Color")
                selectedColor: tempTaskColor
                onAccepted: {
                    tempTaskColor = selectedColor
                    taskColorPreview.color = tempTaskColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Completed task color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: completedTaskColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempCompletedTaskColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: completedTaskColorDialog.open()
                }
            }
            ColorDialog {
                id: completedTaskColorDialog
                title: i18n("Choose Completed Task Color")
                selectedColor: tempCompletedTaskColor
                onAccepted: {
                    tempCompletedTaskColor = selectedColor
                    completedTaskColorPreview.color = tempCompletedTaskColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Task text color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: taskTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempTaskTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: taskTextColorDialog.open()
                }
            }
            ColorDialog {
                id: taskTextColorDialog
                title: i18n("Choose Task Text Color")
                selectedColor: tempTaskTextColor
                onAccepted: {
                    tempTaskTextColor = selectedColor
                    taskTextColorPreview.color = tempTaskTextColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Completed task text color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: completedTaskTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempCompletedTaskTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: completedTaskTextColorDialog.open()
                }
            }
            ColorDialog {
                id: completedTaskTextColorDialog
                title: i18n("Choose Completed Task Text Color")
                selectedColor: tempCompletedTaskTextColor
                onAccepted: {
                    tempCompletedTaskTextColor = selectedColor
                    completedTaskTextColorPreview.color = tempCompletedTaskTextColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Widget text color")
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: widgetTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: tempWidgetTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                PlasmaComponents.Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: widgetTextColorDialog.open()
                }
            }
            ColorDialog {
                id: widgetTextColorDialog
                title: i18n("Choose Widget Text Color")
                selectedColor: tempWidgetTextColor
                onAccepted: {
                    tempWidgetTextColor = selectedColor
                    widgetTextColorPreview.color = tempWidgetTextColor
                    markAsChanged()
                }
            }

            PlasmaComponents.Label {
                text: i18n("Background opacity")
                font.pixelSize: 12
                visible: !hideBackgroundCheckBox.checked
            }
            PlasmaComponents.TextField {
                id: backgroundOpacityField
                visible: !hideBackgroundCheckBox.checked
                Layout.fillWidth: true
                text: tempBackgroundOpacity.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 0 && value <= 1 && value !== tempBackgroundOpacity) {
                        tempBackgroundOpacity = value
                        markAsChanged()
                    }
                }
                validator: DoubleValidator { bottom: 0; top: 1; decimals: 2 }
            }

            PlasmaComponents.Label {
                text: i18n("Task block opacity")
                font.pixelSize: 12
            }
            PlasmaComponents.TextField {
                id: taskOpacityField
                Layout.fillWidth: true
                text: tempTaskOpacity.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 0 && value <= 1 && value !== tempTaskOpacity) {
                        tempTaskOpacity = value
                        markAsChanged()
                    }
                }
                validator: DoubleValidator { bottom: 0; top: 1; decimals: 2 }
            }

            PlasmaComponents.Label {
                text: i18n("Blur radius")
                font.pixelSize: 12
                visible: !hideBackgroundCheckBox.checked
            }
            PlasmaComponents.TextField {
                id: blurRadiusField
                visible: !hideBackgroundCheckBox.checked
                Layout.fillWidth: true
                text: tempBlurRadius.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 0 && value !== tempBlurRadius) {
                        tempBlurRadius = Math.round(value)
                        markAsChanged()
                    }
                }
                validator: IntValidator { bottom: 0; top: 100 }
            }

            PlasmaComponents.Label {
                text: i18n("Widget corner radius")
                font.pixelSize: 12
                visible: !hideBackgroundCheckBox.checked
            }
            PlasmaComponents.TextField {
                visible: !hideBackgroundCheckBox.checked
                id: cornerRadiusField
                Layout.fillWidth: true
                text: tempCornerRadius.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 0 && value !== tempCornerRadius) {
                        tempCornerRadius = Math.round(value)
                        markAsChanged()
                    }
                }
                validator: IntValidator { bottom: 0; top: 100 }
            }

            PlasmaComponents.Label {
                text: i18n("Task block radius")
                font.pixelSize: 12
            }
            PlasmaComponents.TextField {
                id: taskRadiusField
                Layout.fillWidth: true
                text: tempTaskRadius.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 0 && value !== tempTaskRadius) {
                        tempTaskRadius = Math.round(value)
                        markAsChanged()
                    }
                }
                validator: IntValidator { bottom: 0; top: 100 }
            }

            PlasmaComponents.Label {
                text: i18n("Task item height")
                font.pixelSize: 12
            }
            PlasmaComponents.TextField {
                id: taskHeightField
                Layout.fillWidth: true
                text: tempTaskHeight.toString()
                onTextChanged: {
                    var value = Number(text)
                    if (!isNaN(value) && value >= 20 && value !== tempTaskHeight) {
                        tempTaskHeight = Math.round(value)
                        markAsChanged()
                    }
                }
                validator: IntValidator { bottom: 20; top: 200 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                            
                PlasmaComponents.Button {
                    id: applyButton
                    text: i18n("Apply")
                    Layout.fillWidth: true
                    onClicked: applyChanges()
                }
            }
        }
    }
}