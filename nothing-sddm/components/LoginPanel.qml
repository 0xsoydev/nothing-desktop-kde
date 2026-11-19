// Login card in the style of duckpah/Nothing-SDDM (dotted ring avatar, dot password pill, status label),
// with glyph-sddm's LoginPanel API so Main.qml is unchanged. Adds a session pill under the status label.
import QtQuick 2.15

Item {
    id: root
    width: 400
    height: 400

    property color accentColor: "#D71921"
    property color textColor: "white"
    property string fontName: "serif"

    readonly property color cPanel: "#0E0E0E"
    readonly property color cLine: "#2A2A2A"
    readonly property color cGrey: "#8C8C8C"
    readonly property color cFg: "#F2F2F2"

    FontLoader { id: uiFont; source: "../assets/fonts/SpaceGrotesk-Regular.otf" }
    FontLoader { id: monoFont; source: "../assets/fonts/SpaceMono-Regular.ttf" }
    readonly property string fUi: uiFont.name || "Space Grotesk"
    readonly property string fMono: monoFont.name || "Space Mono"

    // API for parent Main.qml
    property int userIndex: 0
    property int sessionIndex: 0
    signal userSelected(int index)
    signal sessionSelected(int index)

    property bool busy: false
    property bool fail: false
    property string info: ""
    property bool blink: true
    property real wave: 0

    Repeater {
        id: users
        model: userModel
        Item {
            visible: false
            property string userName: model.name
            property bool needsPassword: model.needsPassword
        }
    }
    Repeater {
        id: sessions
        model: sessionModel
        Item {
            visible: false
            property string sessionName: model.name
        }
    }

    readonly property var userItem: users.count > 0 ? users.itemAt(Math.max(0, Math.min(userIndex, users.count - 1))) : null
    readonly property string userName: userItem ? userItem.userName : (sddm.lastUser || "")
    readonly property bool needPassword: userItem ? userItem.needsPassword : true
    readonly property string sessionName: sessions.count > 0
        ? sessions.itemAt(Math.max(0, Math.min(sessionIndex, sessions.count - 1))).sessionName : "session"

    readonly property string statusText: {
        if (busy) return "checking…";
        if (fail) return "wrong password · try again";
        if (info) return info;
        if (!needPassword) return "press enter to log in";
        return "enter password";
    }

    function focusPassword() { pass.forceActiveFocus() }
    function reset() {
        pass.text = "";
        busy = false;
        fail = false;
        info = "";
        shake.stop();
        shift.x = 0;
    }
    function triggerError() {
        pass.text = "";
        busy = false;
        fail = true;
        safety.stop();
        shake.restart();
        pass.forceActiveFocus();
    }
    function submit() {
        if (busy || !userName) return;
        busy = true;
        fail = false;
        info = "";
        safety.restart();
        sddm.login(userName, pass.text, sessionIndex);
    }
    function cycleUser(delta) {
        if (users.count < 2) return;
        userSelected((userIndex + delta + users.count) % users.count);
        pass.text = "";
        fail = false;
        pass.forceActiveFocus();
    }
    function cycleSession() {
        if (sessions.count > 1) sessionSelected((sessionIndex + 1) % sessions.count);
        pass.forceActiveFocus();
    }

    Connections {
        target: sddm
        function onInformationMessage(message) { root.busy = false; root.info = message; safety.stop() }
    }

    Timer { interval: 500; running: root.visible; repeat: true; onTriggered: root.blink = !root.blink }
    Timer {
        id: safety
        interval: 20000
        onTriggered: if (root.busy) { root.busy = false; root.info = "no response · try again" }
    }
    NumberAnimation on wave { running: root.busy; from: 0; to: 1; duration: 700; loops: Animation.Infinite }

    SequentialAnimation {
        id: shake
        loops: 2
        NumberAnimation { target: shift; property: "x"; to: -8; duration: 40; easing.type: Easing.OutCubic }
        NumberAnimation { target: shift; property: "x"; to: 8; duration: 40; easing.type: Easing.OutCubic }
        NumberAnimation { target: shift; property: "x"; to: 0; duration: 40; easing.type: Easing.OutCubic }
    }

    Column {
        anchors.centerIn: parent
        spacing: 16
        transform: Translate { id: shift }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96
            height: 96

            Ring {
                anchors.fill: parent
                n: 32
                dot: 6
                f: root.visible ? 1 : 0
                on: root.fail ? root.accentColor : root.cFg
                off: root.cLine
            }

            // No source/home: always the dotted conical-gradient placeholder.
            Avatar {
                anchors.centerIn: parent
                width: 60
                height: 60
                dots: true
                step: 3
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: users.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: users.count > 1 ? root.cycleUser(1) : pass.forceActiveFocus()
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Text {
                visible: users.count > 1
                text: "‹"
                color: root.cGrey
                font { family: root.fUi; pixelSize: 22 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleUser(-1) }
            }
            Text {
                text: root.userName
                color: root.cFg
                font { family: root.fUi; pixelSize: 22 }
            }
            Text {
                visible: users.count > 1
                text: "›"
                color: root.cGrey
                font { family: root.fUi; pixelSize: 22 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleUser(1) }
            }
        }

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: 58
            radius: 29
            clip: true
            color: root.cPanel
            border { width: 1; color: root.fail ? root.accentColor : root.cLine }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Repeater {
                    model: Math.min(pass.text.length, 16)
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        radius: 5.5
                        color: root.cFg
                        opacity: root.busy && Math.abs(root.wave * (Math.min(pass.text.length, 16) + 2) - 1 - index) > 1.2 ? 0.3 : 1
                        NumberAnimation on scale { from: 0.2; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 24
                    color: root.accentColor
                    opacity: root.blink && pass.activeFocus ? 1 : 0
                }

                Repeater {
                    model: Math.max(0, 6 - Math.min(pass.text.length, 16))
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        radius: 5.5
                        color: root.cLine
                    }
                }
            }

            TextInput {
                id: pass
                anchors.fill: parent
                opacity: 0
                echoMode: TextInput.Password
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                cursorVisible: false
                readOnly: root.busy
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase

                onAccepted: root.submit()
                onTextChanged: {
                    if (root.fail && text.length > 0) root.fail = false;
                    if (root.info) root.info = "";
                }
                Keys.onPressed: event => {
                    if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && text.length === 0 && users.count > 1) {
                        root.cycleUser(event.key === Qt.Key_Left ? -1 : 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape && text.length > 0) {
                        text = "";
                        root.fail = false;
                        event.accepted = true; // empty field: Escape goes up to Main.qml and locks again
                    }
                }
            }
        }

        Lb {
            anchors.horizontalCenter: parent.horizontalCenter
            family: root.fMono
            color: root.fail ? root.accentColor : root.cGrey
            text: root.statusText
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: sessionLabel.implicitWidth + 32
            height: 28
            radius: 14
            color: sessionArea.containsMouse ? root.cLine : "transparent"
            border { width: 1; color: root.cLine }

            Lb {
                id: sessionLabel
                anchors.centerIn: parent
                px: 10
                family: root.fMono
                color: root.cGrey
                text: root.sessionName + (sessions.count > 1 ? "  ›" : "")
            }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: sessions.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.cycleSession()
            }
        }

        Lb {
            anchors.horizontalCenter: parent.horizontalCenter
            px: 10
            family: root.fMono
            color: root.accentColor
            visible: keyboard.capsLock
            text: "caps lock"
        }
    }
}
