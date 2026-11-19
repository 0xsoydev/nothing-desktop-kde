// Ported from PowerMenu.qml in uzayr-iqbal-hamid/nothing-os-dots-hyprland (MIT licence), Quickshell -> layer-shell-qt.
// Lock and sleep run at once; log out, restart and shut down turn red and wait for a second press.
// Keys: arrows or Tab move, 1-5 pick, Enter runs, Escape (or a click on the backdrop) closes.
import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.layershell as LayerShell

Window {
    id: panel
    visible: false
    transientParent: null
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShell.Window.scope: "nothing-powermenu"
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                               | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.exclusionZone: -1
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityExclusive
    LayerShell.Window.wantsToBeOnActiveScreen: true

    // Nothing OS tokens (Theme.qml upstream)
    readonly property color text: "#FFFFFF"
    readonly property color textDim: "#8C8C8C"
    readonly property color textFaint: "#5A5A5A"
    readonly property color accent: "#D71921"
    readonly property color pill: "#FFFFFF"
    readonly property color pillText: "#000000"
    readonly property color surface: "#1AFFFFFF"
    readonly property color outline: "#2E2E2E"
    readonly property string fontDot: "Ndot 57 Aligned"
    readonly property string fontLabel: "Space Mono"

    property bool shown: false
    property int current: 0
    property int armed: -1 // button waiting for its confirming press
    property date now: new Date()

    readonly property var actions: [
        { icon: "system-lock-screen", label: "Lock", confirm: false, cmd: ["loginctl", "lock-session"] },
        { icon: "system-suspend", label: "Sleep", confirm: false, cmd: ["systemctl", "suspend"] },
        { icon: "system-log-out", label: "Log out", confirm: true, cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logout"] },
        { icon: "system-reboot", label: "Restart", confirm: true, cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndReboot"] },
        { icon: "system-shutdown", label: "Shut down", confirm: true, cmd: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndShutdown"] }
    ]

    function toggle() {
        if (shown) {
            close();
            return;
        }
        current = 0;
        armed = -1;
        now = new Date();
        visible = true;
        shown = true;
        requestActivate();
        backdrop.forceActiveFocus();
    }
    function close() { shown = false; }
    onActiveChanged: if (active) backdrop.forceActiveFocus()

    function move(step) {
        current = (current + step + actions.length) % actions.length;
        armed = -1;
    }

    function activate(index) {
        current = index;
        if (actions[index].confirm && armed !== index) {
            armed = index;
            disarm.restart();
            return;
        }
        close();
        Exec.run(actions[index].cmd);
    }

    Timer { id: disarm; interval: 4000; onTriggered: panel.armed = -1 }
    Timer { interval: 1000; repeat: true; running: panel.visible; onTriggered: panel.now = new Date() }

    BlurBehind {
        anchors.fill: parent
        active: panel.visible
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#B3000000"
        opacity: panel.shown ? 1 : 0
        focus: true

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        onOpacityChanged: if (opacity === 0 && !panel.shown) panel.visible = false

        Keys.onPressed: event => {
            const key = event.key;
            if (key === Qt.Key_Escape)
                panel.close();
            else if (key === Qt.Key_Left || key === Qt.Key_Backtab || key === Qt.Key_Up)
                panel.move(-1);
            else if (key === Qt.Key_Right || key === Qt.Key_Tab || key === Qt.Key_Down)
                panel.move(1);
            else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
                panel.activate(panel.current);
            else if (key >= Qt.Key_1 && key <= Qt.Key_5)
                panel.activate(key - Qt.Key_1);
            else
                return;
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: panel.close()
        }

        Column {
            anchors.centerIn: parent
            spacing: 24

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(panel.now, "HH:mm")
                color: panel.text
                font.family: panel.fontDot
                font.pixelSize: 56
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                Repeater {
                    model: panel.actions
                    delegate: PowerButton {
                        required property int index
                        required property var modelData
                        buttonIndex: index
                        icon: modelData.icon
                        label: modelData.label
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: panel.armed >= 0 ? "PRESS AGAIN TO CONFIRM" : "ESC TO CANCEL"
                color: panel.armed >= 0 ? panel.accent : panel.textFaint
                font.family: panel.fontLabel
                font.pixelSize: 9
                font.letterSpacing: 1.2
            }
        }
    }

    component PowerButton: Item {
        id: button

        property int buttonIndex
        property string icon
        property string label
        readonly property bool selected: panel.current === buttonIndex
        readonly property bool armed: panel.armed === buttonIndex

        width: 92
        height: circle.height + 12 + caption.implicitHeight

        Rectangle {
            id: circle
            anchors.horizontalCenter: parent.horizontalCenter
            width: 72
            height: 72
            radius: 36
            color: button.armed ? panel.accent : button.selected ? panel.pill : panel.surface
            border.width: 1
            border.color: button.selected || button.armed ? "transparent" : panel.outline

            Behavior on color { ColorAnimation { duration: 120 } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 26
                height: 26
                source: button.icon
                isMask: true
                color: button.armed ? panel.text : button.selected ? panel.pillText : panel.text
            }
        }

        Text {
            id: caption
            anchors.top: circle.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            text: (button.armed ? "Confirm" : button.label).toUpperCase()
            color: button.armed ? panel.accent : button.selected ? panel.text : panel.textDim
            font.family: panel.fontLabel
            font.pixelSize: 9
            font.letterSpacing: 1.2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (panel.current !== button.buttonIndex)
                    panel.armed = -1;
                panel.current = button.buttonIndex;
            }
            onClicked: panel.activate(button.buttonIndex)
        }
    }
}
