import QtQuick
import Neat.UI as UI

// Remote's loading splash (board 12.5, LoSplash.dc), shown at once on every
// start, as Write and Tables do, for long enough to read before the home
// window takes over.
UI.LoadingSplash {
    appName: qsTr("Remote")
    iconSource: "qrc:/qt/qml/Neat/Remote/data/io.github.neatpluszero.NeatRemote.svg"
    accent: "#ffc25a"
    accentDeep: "#e2700f"
    status: qsTr("Opening your hosts")
    noteStart: qsTr("Terminal and remote desktop in one")
    noteEnd: qsTr("No cloud sync")
    showDelay: 0
    minimumTime: 1000
}
