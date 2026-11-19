// Nothing lock screen: glyph-sddm's background and clock with the duckpah/Nothing-SDDM-style card
// (same look as ~/src/nothing-sddm). Unlocks through kscreenlocker's `authenticator`, following
// Plasma's own LockScreenUi.qml: startAuthenticating() when shown, respond(password), Qt.quit() on success.
import QtQuick

Item {
    id: root

    // Properties and signals kscreenlocker looks for.
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()
    property bool viewVisible: false

    implicitWidth: 800
    implicitHeight: 600

    readonly property color accent: "#D71921"
    readonly property color cPanel: "#0E0E0E"
    readonly property color cLine: "#2A2A2A"
    readonly property color cGrey: "#8C8C8C"
    readonly property color cFg: "#F2F2F2"

    FontLoader { id: ndotFont; source: "assets/fonts/Ndot-57-Aligned.ttf" }
    FontLoader { id: symbolFont; source: "assets/fonts/SymbolsNerdFont.ttf" }
    FontLoader { id: uiFont; source: "assets/fonts/SpaceGrotesk-Regular.otf" }
    FontLoader { id: monoFont; source: "assets/fonts/SpaceMono-Regular.ttf" }
    readonly property string fDot: ndotFont.name || "monospace"
    readonly property string fUi: uiFont.name || "Space Grotesk"
    readonly property string fMono: monoFont.name || "Space Mono"

    property bool revealed: false
    property bool busy: false
    property bool fail: false
    property bool noPrompt: false // authenticated without a password: Enter unlocks
    property string info: ""
    property bool blink: true
    property real wave: 0

    readonly property string statusText: {
        if (authenticator.graceLocked) return "please wait…";
        if (busy) return "checking…";
        if (fail) return "wrong password · try again";
        if (info) return info;
        if (noPrompt) return "press enter to unlock";
        return "enter password";
    }

    onClearPassword: pass.text = ""
    onViewVisibleChanged: if (viewVisible) keys.forceActiveFocus()
    Component.onCompleted: keys.forceActiveFocus()

    function reveal(initialText) {
        idle.restart();
        if (revealed) return;
        revealed = true;
        authenticator.startAuthenticating();
        pass.text = initialText || "";
        Qt.callLater(() => pass.forceActiveFocus());
    }
    function conceal() {
        revealed = false;
        pass.text = "";
        fail = false;
        info = "";
        keys.forceActiveFocus();
    }
    function submit() {
        if (noPrompt) { Qt.quit(); return; }
        if (busy || authenticator.graceLocked) return;
        busy = true;
        fail = false;
        info = "";
        authenticator.respond(pass.text);
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) return; // non-interactive authenticators (fingerprint etc.)
            root.busy = false;
            root.fail = true;
            pass.text = "";
            shake.restart();
            graceTimer.restart();
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) Qt.quit();
            else { root.busy = false; root.noPrompt = true; }
        }
        function onInfoMessageChanged() { root.info = authenticator.infoMessage }
        function onErrorMessageChanged() { root.info = authenticator.errorMessage }
        function onPromptForSecretChanged() { root.busy = false; if (root.revealed) pass.forceActiveFocus() }
    }

    Timer {
        id: graceTimer
        interval: 3000
        onTriggered: { root.clearPassword(); authenticator.startAuthenticating(); }
    }
    // Back to the clock after 30 s without input, like Plasma's fading lock screen UI.
    Timer { id: idle; interval: 30000; onTriggered: if (pass.text === "" && !root.busy) root.conceal() }
    Timer { interval: 500; running: root.revealed; repeat: true; onTriggered: root.blink = !root.blink }
    NumberAnimation on wave { running: root.busy; from: 0; to: 1; duration: 700; loops: Animation.Infinite }

    Rectangle { anchors.fill: parent; color: "black" }

    Image {
        anchors.fill: parent
        source: "assets/images/background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.revealed ? 0.45 : 0.15
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    // Swallows keys before the card is shown; the first printable key starts the password.
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (!root.revealed) {
                root.reveal(event.text.length === 1 && event.text >= " " ? event.text : "");
                event.accepted = true;
            }
        }
        Keys.onEscapePressed: if (root.revealed) root.conceal()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.revealed ? pass.forceActiveFocus() : root.reveal("")
    }

    Clock {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 80
        fontName: root.fDot
        symbolFontName: symbolFont.name
        textColor: "white"
        opacity: root.revealed ? 0.4 : 1.0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        text: "PRESS ANY KEY TO UNLOCK"
        font.family: root.fDot
        font.pixelSize: 14
        font.letterSpacing: 1
        color: "white"
        opacity: root.revealed ? 0 : 0.6
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }

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
        opacity: root.revealed ? 1 : 0
        visible: opacity > 0
        scale: root.revealed ? 1 : 0.95
        transform: Translate { id: shift }
        Behavior on opacity { NumberAnimation { duration: 350 } }
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96
            height: 96

            Ring {
                anchors.fill: parent
                n: 32
                dot: 6
                f: root.revealed ? 1 : 0
                on: root.fail ? root.accent : root.cFg
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
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: kscreenlocker_userName
            color: root.cFg
            font { family: root.fUi; pixelSize: 22 }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: 58
            radius: 29
            clip: true
            color: root.cPanel
            border { width: 1; color: root.fail ? root.accent : root.cLine }

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
                    color: root.accent
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
                readOnly: root.busy || authenticator.graceLocked
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase

                onAccepted: root.submit()
                onTextChanged: {
                    idle.restart();
                    if (root.fail && text.length > 0) root.fail = false;
                    if (root.info) root.info = "";
                }
                Keys.onEscapePressed: {
                    if (text.length > 0) { text = ""; root.fail = false; }
                    else root.conceal();
                }
            }
        }

        Lb {
            anchors.horizontalCenter: parent.horizontalCenter
            family: root.fMono
            color: root.fail ? root.accent : root.cGrey
            text: root.statusText
        }
    }
}
