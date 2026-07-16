import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page
    width: 400
    height: 620
    
    property alias cfg_hideBackground: hideBackgroundCheckBox.checked
    property alias cfg_enableBlur: enableBlurCheckBox.checked
    property alias cfg_titleAlignmentCenter: titleAlignmentCheckBox.checked
    property alias cfg_widgetTitle: widgetTitleSpin.text
    property alias cfg_widgetColor: widgetColorDialog.selectedColor
    property alias cfg_taskColor: taskColorDialog.selectedColor
    property alias cfg_completedTaskColor: completedTaskColorDialog.selectedColor
    property alias cfg_taskTextColor: taskTextColorDialog.selectedColor
    property alias cfg_completedTaskTextColor: completedTaskTextColorDialog.selectedColor
    property alias cfg_widgetTextColor: widgetTextColorDialog.selectedColor
    property alias cfg_backgroundOpacity: backgroundOpacitySpin.value
    property alias cfg_taskOpacity: taskOpacitySpin.value
    property alias cfg_blurRadius: blurRadiusSpin.value
    property alias cfg_cornerRadius: cornerRadiusSpin.value
    property alias cfg_taskRadius: taskRadiusSpin.value
    property alias cfg_taskHeight: taskHeightSpin.value
    
    
    ScrollView {
        id: control
        focus: true
        width: page.availableWidth
        height: page.availableHeight
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
        Kirigami.FormLayout {
            width: control.availableWidth
            anchors {
                left: control.left
                right: control.right
                top: control.top
            }

            CheckBox {
                id: hideBackgroundCheckBox
                Kirigami.FormData.label: i18n("Hide background")
            }

            CheckBox {
                id: enableBlurCheckBox
                Kirigami.FormData.label: i18n("Enable blur")
                visible: !hideBackgroundCheckBox.checked
            }

            TextField {
                Kirigami.FormData.label: i18n("Title")
                id: widgetTitleSpin
                Layout.fillWidth: true
            }

            CheckBox {
                id: titleAlignmentCheckBox
                Kirigami.FormData.label: i18n("Center title alignment")
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Main color")
                spacing: 10

                Rectangle {
                    id: colorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_widgetColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: widgetColorDialog.open()
                }
            }
            ColorDialog {
                id: widgetColorDialog
                selectedColor: cfg_widgetColor
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Task color")
                spacing: 10

                Rectangle {
                    id: taskColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_taskColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: taskColorDialog.open()
                }
            }
            ColorDialog {
                id: taskColorDialog
                title: i18n("Choose Task Color")
                selectedColor: cfg_taskColor
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Completed task color")
                spacing: 10

                Rectangle {
                    id: completedTaskColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_completedTaskColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: completedTaskColorDialog.open()
                }
            }
            ColorDialog {
                id: completedTaskColorDialog
                title: i18n("Choose Completed Task Color")
                selectedColor: cfg_completedTaskColor
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Task text color")
                spacing: 10

                Rectangle {
                    id: taskTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_taskTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: taskTextColorDialog.open()
                }
            }
            ColorDialog {
                id: taskTextColorDialog
                title: i18n("Choose Task Text Color")
                selectedColor: cfg_taskTextColor
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Completed task text color")
                spacing: 10

                Rectangle {
                    id: completedTaskTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_completedTaskTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: completedTaskTextColorDialog.open()
                }
            }
            ColorDialog {
                id: completedTaskTextColorDialog
                title: i18n("Choose Completed Task Text Color")
                selectedColor: cfg_completedTaskTextColor
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.FormData.label: i18n("Widget text color")
                spacing: 10

                Rectangle {
                    id: widgetTextColorPreview
                    width: 34
                    height: 28
                    radius: 6
                    color: cfg_widgetTextColor
                    border.color: "#718096"
                    Layout.fillWidth: true
                    border.width: 1
                }

                Button {
                    text: i18n("Choose color")
                    Layout.fillWidth: true
                    onClicked: widgetTextColorDialog.open()
                }
            }
            ColorDialog {
                id: widgetTextColorDialog
                title: i18n("Choose Widget Text Color")
                selectedColor: cfg_widgetTextColor
            }

            SpinBox {
                id: backgroundOpacitySpin
                Kirigami.FormData.label: i18n("Background opacity")
                visible: !hideBackgroundCheckBox.checked
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
            }

            SpinBox {
                id: taskOpacitySpin
                Kirigami.FormData.label: i18n("Task block opacity")
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
            }

            SpinBox {
                id: blurRadiusSpin
                Kirigami.FormData.label: i18n("Blur radius")
                visible: !hideBackgroundCheckBox.checked
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
            }

            SpinBox {
                visible: !hideBackgroundCheckBox.checked
                id: cornerRadiusSpin
                Kirigami.FormData.label: i18n("Widget corner radius")
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
            }

            SpinBox {
                id: taskRadiusSpin
                Kirigami.FormData.label: i18n("Task block radius")
                Layout.fillWidth: true
                from: 0
                to: 100
                stepSize: 1
            }

            SpinBox {
                id: taskHeightSpin
                Kirigami.FormData.label: i18n("Task item height")
                Layout.fillWidth: true
                from: 20
                to: 200
                stepSize: 1
            }
        }
    }
}