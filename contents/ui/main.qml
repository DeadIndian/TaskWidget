import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Controls as Controls

import "code/tasks.js" as TaskUtils

PlasmoidItem {
    id: root

    property bool hideBackground: plasmoid.configuration.hideBackground || false
    property bool titleAlignmentCenter:titleAlignmentCenter = plasmoid.configuration.titleAlignmentCenter || false
    property string widgetTitle: plasmoid.configuration.widgetTitle || i18n("Tasks")
    property string widgetColor: plasmoid.configuration.widgetColor || "#2d3748"
    property string taskColor: plasmoid.configuration.taskColor || "#5e3a6b"
    property string completedTaskColor: plasmoid.configuration.completedTaskColor || "#2f855a"
    property string taskTextColor: plasmoid.configuration.taskTextColor || "#ffffff"
    property string completedTaskTextColor: plasmoid.configuration.completedTaskTextColor || "#cbd5e0"
    property string widgetTextColor: plasmoid.configuration.widgetTextColor || "#ffffff"
    property real backgroundOpacity: Number(plasmoid.configuration.backgroundOpacity/100 || 0.95)
    property real taskOpacity: Number(plasmoid.configuration.taskOpacity/100 || 0.95)
    property bool enableBlur: plasmoid.configuration.enableBlur || false
    property real blurRadius: Number(plasmoid.configuration.blurRadius || 8)
    property int cornerRadius: Number(plasmoid.configuration.cornerRadius || 16)
    property int taskRadius: Number(plasmoid.configuration.taskRadius || 12)
    property int taskHeight: Number(plasmoid.configuration.taskHeight || 56)

    property int completedTasks: TaskUtils.completedCount(taskModel)
    property bool widgetHovered: false
    property bool editingTask: false

    Plasmoid.backgroundHints: hideBackground
        ? (PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground)
        : (PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground)

    ListModel {
        id: taskModel
    }

    property var defaultTasks: [
        { id: 1, description: "Complete project documentation", completed: false },
        { id: 2, description: "Review code changes", completed: true },
        { id: 3, description: "Fix critical bugs", completed: false }
    ]

    Component.onCompleted: {
        loadTasks()
    }

    function loadTasks() {
        var storedTasks = plasmoid.configuration.tasks
        if (typeof storedTasks === "string") {
            try {
                storedTasks = JSON.parse(storedTasks)
            } catch (e) {
                storedTasks = null
            }
        }
        TaskUtils.loadTasks(taskModel, storedTasks, defaultTasks)
        completedTasks = TaskUtils.completedCount(taskModel)
    }

    function saveTasks() {
        var arr = TaskUtils.modelToArray(taskModel)
        plasmoid.configuration.tasks = JSON.stringify(arr)
        completedTasks = TaskUtils.completedCount(taskModel)
    }

    function addTask() {
        TaskUtils.appendTask(taskModel, i18n("New task"))
        saveTasks()
    }

    function deleteTask(index) {
        if (index >= 0 && index < taskModel.count) {
            taskModel.remove(index)
            saveTasks()
        }
    }

    function clearCompletedTasks() {
        TaskUtils.removeCompleted(taskModel)
        saveTasks()
    }

    Rectangle {
        id: widgetBackground
        anchors.fill: parent
        z: 0
        color: hideBackground ? "transparent" : widgetColor
        border.color: hideBackground ? "transparent" : "#607080"
        border.width: hideBackground ? 0 : 1
        radius: cornerRadius
        opacity: hideBackground ? 1 : backgroundOpacity
        layer.enabled: enableBlur && !hideBackground
        layer.effect: FastBlur {
            radius: blurRadius
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4
        z: 1

        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            PlasmaComponents.Label {
                text: widgetTitle
                font.bold: true
                horizontalAlignment: titleAlignmentCenter ? Text.AlignHCenter : Text.AlignLeft
                font.pixelSize: 18
                Layout.fillWidth: true
                color: widgetTextColor
            }

            Controls.Button {
                id: addButton
                implicitWidth: 34
                implicitHeight: 34
                font.bold: true
                opacity: root.widgetHovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }

                contentItem: Text {
                    text: i18n("+")
                    font.pixelSize: 18
                    font.bold: true
                    color: widgetTextColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: widgetColor
                    border.color: "#718096"
                    border.width: 1
                    radius: 8
                }
                onClicked: addTask()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            height: 24
            opacity: root.widgetHovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            PlasmaComponents.Label {
                text: taskModel.count + " " + i18n("tasks, ") + completedTasks + " " + i18n("completed")
                font.pixelSize: 12
                color: widgetTextColor
            }

            PlasmaComponents.Button {
                visible: taskModel.count > 0
                leftPadding: 8
                rightPadding: 8
                text: i18n("Clear completed")
                font.pixelSize: 12
                onClicked: clearCompletedTasks()
                background: Rectangle {
                    color: "#2d37486e"
                    radius: 5
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: taskListView
                anchors.fill: parent
                model: taskModel
                delegate: taskDelegate
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: !editingTask
            }

            PlasmaComponents.Label {
                text: i18n("No tasks yet. Click + to add one.")
                visible: taskModel.count === 0
                anchors.centerIn: parent
                font.italic: true
                color: "#a0aec0"
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 100
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onEntered: {
            root.widgetHovered = true
        }
        onExited: {
            root.widgetHovered = false
        }
    }

    Component {
        id: taskDelegate

        Rectangle {
            id: taskItem
            width: ListView.view ? ListView.view.width : 200
            height: {
                if (editing) {
                    return Math.max(taskHeight, taskEditor.implicitHeight + 32)
                } else {
                    return Math.max(taskHeight, taskLabel.contentHeight + 16)
                }
            }

            property bool editing: false

            color: {
                var baseColor = (model && model.completed) ? completedTaskColor : taskColor
                return Qt.rgba(Qt.color(baseColor).r, Qt.color(baseColor).g, Qt.color(baseColor).b, taskOpacity)
            }
            radius: taskRadius
            border.color: Qt.rgba(Qt.color("#607080").r, Qt.color("#607080").g, Qt.color("#607080").b, taskOpacity)
            border.width: 1
            clip: true
            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on height { NumberAnimation { duration: 120 } }

            MouseArea {
                id: taskArea
                anchors.fill: parent
                z: 20
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
            }

            onEditingChanged: {
                if (editing) {
                    taskEditor.forceActiveFocus()
                    taskEditor.selectAll()
                }
            }

            Item {
                id: taskContent
                anchors.fill: parent
                anchors.margins: 8
                z: 1

                Controls.CheckBox {
                    id: taskCheckbox
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    checked: model && model.completed
                    visible: root.widgetHovered && !taskItem.editing
                    opacity: root.widgetHovered && !taskItem.editing ? 1 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on visible { PropertyAnimation { duration: 220 } }
                    implicitWidth: 22
                    implicitHeight: 22
                    onCheckedChanged: {
                        if (typeof index !== "undefined" && index >= 0) {
                            taskModel.setProperty(index, "completed", checked)
                            saveTasks()
                        }
                    }
                }

                Item {
                    id: taskLabelWrapper
                    anchors.left: taskCheckbox.right
                    anchors.leftMargin: 2
                    anchors.right: editButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    visible: !taskItem.editing

                    Text {
                        id: taskLabel
                        anchors.fill: parent
                        text: model && model.description ? model.description : ""
                        color: model && model.completed ? completedTaskTextColor : taskTextColor
                        font.italic: model && model.completed
                        font.strikeout: model && model.completed
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        onDoubleClicked: {
                            taskItem.editing = false
                            editingTask = false
                        }
                        onClicked: {
                            taskCheckbox.checked = !taskCheckbox.checked
                            mouse.accepted = true
                        }
                    }
                }
                Controls.TextArea {
                    id: taskEditor
                    text: model && model.description ? model.description : ""
                    visible: taskItem.editing
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.ShiftModifier) {
                                event.accepted = true
                                insert(cursorPosition, "\n")
                            } else {
                                event.accepted = true
                                
                                if (text.trim() !== "") {
                                    if (typeof index !== "undefined" && index >= 0) {
                                        taskModel.setProperty(index, "description", text.trim())
                                        saveTasks()
                                    }
                                } else {
                                    text = model && model.description ? model.description : ""
                                }
                                taskItem.editing = false
                                editingTask = false
                                root.forceActiveFocus()
                            }
                        }
                    } 
                    anchors.left: taskCheckbox.right
                    anchors.leftMargin: 8
                    anchors.right: editButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 13
                    cursorVisible: true
                    focus: true
                    selectByMouse: true

                    background: Rectangle {
                        color: "#2d3748"
                        border.color: "#718096"
                        border.width: 1
                        radius: 6
                    }

                    Keys.onEscapePressed: {
                        text = model && model.description ? model.description : ""
                        taskItem.editing = false
                        editingTask = false
                        root.forceActiveFocus()
                    }
                }

                Controls.Button {
                    id: editButton
                    anchors.right: deleteButton.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 18
                    implicitHeight: 18
                    visible: root.widgetHovered && !taskItem.editing
                    opacity: root.widgetHovered && !taskItem.editing ? 1 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on visible { PropertyAnimation { duration: 220 } }
                    contentItem: Text {
                        text: i18n("✎")
                        font.pixelSize: 12
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: editButton.hovered ? "#4a5568" : "#2d3748"
                        border.color: "#718096"
                        border.width: 1
                        radius: 6
                    }
                    onClicked: {
                        taskItem.editing = true
                        editingTask = true
                    }
                }

                Controls.Button {
                    id: deleteButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 18
                    implicitHeight: 18
                    visible: root.widgetHovered && !taskItem.editing
                    opacity: root.widgetHovered && !taskItem.editing ? 1 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on visible { PropertyAnimation { duration: 220 } }

                    hoverEnabled: true
                    contentItem: Text {
                        text: i18n("×")
                        font.pixelSize: 14
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: "#e53e3e"
                        border.color: "#c53030"
                        border.width: 1
                        radius: 6
                    }
                    onClicked: deleteTask(typeof index !== "undefined" && index >= 0 ? index : -1)
                }
            }
        }
    }
}