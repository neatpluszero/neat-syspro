pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Templates as T
import Neat.Files
import Neat.UI as UI

// The places column from FilesDetails.dc.html: the Home folders, then
// This computer and the drives. The Recycle Bin is first, above Home.
Item {
    id: sidebar

    required property var folder
    required property var view
    readonly property int currentRow: folder && PlacesModel.revision >= 0 ? PlacesModel.rowFor(folder.url) : -1
    readonly property bool focused: list.activeFocus
    // The width while its edge is being dragged; 0 otherwise.
    property int dragWidth: 0
    // Narrow windows keep room for the files whatever width was chosen.
    readonly property int widest: parent ? Math.max(140, Math.min(420, parent.width - 360)) : 420

    width: dragWidth > 0 ? dragWidth : Math.min(Settings.sidebarWidth, widest)

    function takeFocus() {
        view.keyboardUsed = true;
        list.forceActiveFocus(Qt.TabFocusReason);
    }

    // The next place up or down from a row, stepping over the dividers.
    function stepFrom(row, by) {
        for (let i = row + by; i >= 0 && i < list.count; i += by) {
            if (PlacesModel.get(i).kind !== "separator") {
                return i;
            }
        }
        return row;
    }

    function handleKey(event) {
        const row = list.currentIndex;
        switch (event.key) {
        case Qt.Key_Up:
            list.currentIndex = stepFrom(row, -1);
            break;
        case Qt.Key_Down:
            list.currentIndex = stepFrom(row, 1);
            break;
        case Qt.Key_Home:
            list.currentIndex = stepFrom(-1, 1);
            break;
        case Qt.Key_End:
            list.currentIndex = stepFrom(list.count, -1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            if (row >= 0) {
                open(PlacesModel.get(row), (event.modifiers & Qt.ControlModifier) !== 0);
            }
            break;
        case Qt.Key_Menu:
            openMenuAt(row);
            break;
        case Qt.Key_F10:
            if (!(event.modifiers & Qt.ShiftModifier)) {
                return;
            }
            openMenuAt(row);
            break;
        case Qt.Key_Escape:
            view.focusContent();
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    function openMenuAt(row) {
        const item = list.itemAtIndex(row);
        if (item) {
            view.keyboardUsed = true;
            view.openPlaceMenu(item, 24, item.height / 2, PlacesModel.get(row));
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Metrics.sidebar
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: UI.Style.divider
        }
    }

    // Local change: a pinned folder is dragged up or down to change the
    // order. reorderFrom is the row being dragged, reorderBefore the row
    // the line is drawn above (one past the last pinned row for the end).
    property int reorderFrom: -1
    property int reorderBefore: -1

    function reorderTo(scenePosition) {
        let first = -1;
        let last = -1;
        for (let i = 0; i < list.count; ++i) {
            if (PlacesModel.get(i).pinned) {
                first = first < 0 ? i : first;
                last = i;
            }
        }
        if (first < 0) {
            reorderBefore = -1;
            return;
        }
        const y = list.mapFromItem(null, scenePosition.x, scenePosition.y).y + list.contentY;
        let row = last + 1;
        for (let i = first; i <= last; ++i) {
            const item = list.itemAtIndex(i);
            if (item && y < item.y + item.height / 2) {
                row = i;
                break;
            }
        }
        reorderBefore = row;
    }

    function finishReorder(url) {
        const from = reorderFrom;
        const before = reorderBefore;
        reorderFrom = -1;
        reorderBefore = -1;
        if (from >= 0 && before >= 0 && before !== from && before !== from + 1) {
            PlacesModel.movePinned(url, before);
        }
    }

    // Local change: a folder dragged onto the sidebar, anywhere that is not
    // a place (those take the drop as a move or copy into them), is pinned.
    function pinnable(urls) {
        return (urls || []).filter(url => PlacesModel.canPin(url));
    }

    DropArea {
        id: pinDrop
        anchors.fill: parent
        property bool offered: false
        onEntered: drag => {
            offered = sidebar.pinnable(drag.urls).length > 0;
            drag.accepted = offered;
            if (offered) {
                drag.accept(Qt.LinkAction);
            }
        }
        onExited: offered = false
        onDropped: drop => {
            const folders = sidebar.pinnable(drop.urls);
            offered = false;
            if (folders.length === 0) {
                return;
            }
            drop.accept(Qt.LinkAction);
            for (const url of folders) {
                PlacesModel.pin(url);
            }
        }
    }

    Rectangle {
        visible: pinDrop.containsDrag && pinDrop.offered
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: 34
        radius: UI.Style.radiusXs
        color: "transparent"
        border.width: 1
        border.color: UI.Style.accent
        UI.Label {
            anchors.centerIn: parent
            text: qsTr("Pin to sidebar")
            color: UI.Style.accent
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 8
        anchors.rightMargin: 9
        spacing: 1
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: PlacesModel
        ScrollBar.vertical: UI.ScrollBar {}
        Accessible.role: Accessible.List
        Accessible.name: qsTr("Places")
        // Tab and F6 bring the keyboard here; it starts on the place that
        // is open. The arrow keys are handled above so they step over the
        // dividers.
        activeFocusOnTab: true
        keyNavigationEnabled: false
        currentIndex: -1
        onActiveFocusChanged: {
            if (activeFocus) {
                currentIndex = sidebar.currentRow >= 0 ? sidebar.currentRow : sidebar.stepFrom(-1, 1);
            }
        }
        Keys.onPressed: event => sidebar.handleKey(event)

        delegate: Item {
            id: place

            required property string name
            required property string iconName
            required property url url
            required property string kind
            required property string udi
            required property bool removable
            required property bool pinned
            required property int index
            readonly property bool current: index === sidebar.currentRow
            readonly property bool focusMarked: list.activeFocus && index === list.currentIndex

            width: ListView.view.width
            height: kind === "separator" ? 17 : Metrics.placeHeight

            Rectangle {
                visible: place.kind === "separator"
                x: 10
                width: parent.width - 20
                height: 1
                anchors.verticalCenter: parent.verticalCenter
                color: Metrics.rule
            }

            T.AbstractButton {
                id: button
                visible: place.kind !== "separator"
                anchors.fill: parent
                hoverEnabled: true
                focusPolicy: Qt.NoFocus
                Accessible.role: Accessible.Button
                Accessible.name: place.name
                Accessible.focused: place.focusMarked
                onClicked: sidebar.open(place, false)

                background: Rectangle {
                    radius: UI.Style.radiusXs
                    color: button.down ? UI.Style.surfacePressed
                         : button.hovered || eject.hovered || placeDrop.containsDrag ? UI.Style.surfaceHover
                         : place.current ? UI.Style.surfaceSelected : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: UI.Style.hoverDuration }
                    }

                    // On the row's own edge: the list clips at its sides.
                    UI.FocusRing {
                        visible: place.focusMarked
                        anchors.margins: 0
                        targetRadius: UI.Style.radiusXs - 4
                    }
                }

                DragHandler {
                    enabled: place.pinned
                    target: null
                    acceptedButtons: Qt.LeftButton
                    onActiveChanged: {
                        if (active) {
                            sidebar.reorderFrom = place.index;
                            sidebar.reorderTo(centroid.scenePosition);
                        } else {
                            sidebar.finishReorder(place.url);
                        }
                    }
                    onCentroidChanged: {
                        if (active) {
                            sidebar.reorderTo(centroid.scenePosition);
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.MiddleButton | Qt.RightButton
                    onTapped: (point, pressed) => {
                        if (pressed === Qt.MiddleButton) {
                            sidebar.open(place, true);
                        } else {
                            sidebar.view.openPlaceMenu(button, point.position.x, point.position.y, place);
                        }
                    }
                }

                UI.Icon {
                    id: icon
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    name: place.iconName
                    size: 16
                    strokeWidth: 1.8
                    color: place.current ? UI.Style.accent : UI.Style.ink
                }

                UI.Label {
                    anchors.left: icon.right
                    anchors.leftMargin: 10
                    anchors.right: eject.visible ? eject.left : pinMark.visible ? pinMark.left : parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: place.name
                    font.weight: place.current ? UI.Style.weightMedium : UI.Style.weightRegular
                }

                // Local change: pinned places carry a pin at the right.
                UI.Icon {
                    id: pinMark
                    visible: place.pinned
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    name: "pin"
                    size: 12
                    strokeWidth: 1.6
                    color: UI.Style.inkSubtle
                }

                UI.IconButton {
                    id: eject
                    visible: place.removable && place.url.toString().length > 0 && (button.hovered || hovered)
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: UI.Style.radiusXs
                    iconName: "eject"
                    iconSize: 13
                    tip: qsTr("Eject %1").arg(place.name)
                    focusPolicy: Qt.NoFocus
                    onClicked: FileOps.ejectDrive(place.udi)
                }

                DropArea {
                    id: placeDrop
                    anchors.fill: parent
                    enabled: place.kind !== "computer" && place.url.toString().length > 0
                    onEntered: drag => drag.accept(drag.proposedAction)
                    onDropped: drop => sidebar.view.dropUrls(drop, place.url)
                }
            }
        }
    }

    // Where a pinned folder being dragged would land.
    Rectangle {
        readonly property Item above: sidebar.reorderBefore > 0 ? list.itemAtIndex(sidebar.reorderBefore - 1) : null
        readonly property Item below: sidebar.reorderBefore >= 0 ? list.itemAtIndex(sidebar.reorderBefore) : null
        visible: sidebar.reorderFrom >= 0 && sidebar.reorderBefore >= 0 && (above !== null || below !== null)
            && sidebar.reorderBefore !== sidebar.reorderFrom && sidebar.reorderBefore !== sidebar.reorderFrom + 1
        x: list.x + 6
        width: list.width - 12
        height: 2
        radius: 1
        color: UI.Style.accent
        y: list.y - list.contentY - 1 + (sidebar.reorderBefore > sidebar.reorderFrom && above ? above.y + above.height : below ? below.y : 0)
    }

    // The edge between the places and the files: drag it to make the
    // places wider or narrower, double-click to put it back.
    MouseArea {
        id: grip
        anchors.right: parent.right
        anchors.rightMargin: -3
        width: 7
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        Accessible.role: Accessible.Separator
        Accessible.name: qsTr("Sidebar width")
        property real startX
        property int startWidth

        onPressed: mouse => {
            startX = mapToItem(null, mouse.x, 0).x;
            startWidth = sidebar.width;
        }
        onPositionChanged: mouse => {
            if (pressed) {
                sidebar.dragWidth = Math.max(140, Math.min(sidebar.widest, Math.round(startWidth + mapToItem(null, mouse.x, 0).x - startX)));
            }
        }
        onReleased: {
            if (sidebar.dragWidth > 0) {
                Settings.sidebarWidth = sidebar.dragWidth;
                sidebar.dragWidth = 0;
            }
        }
        onDoubleClicked: Settings.sidebarWidth = Metrics.sidebarWidth

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: grip.pressed ? 2 : 1
            height: parent.height
            color: UI.Style.accent
            opacity: grip.pressed ? 1 : grip.containsMouse ? 0.6 : 0
            Behavior on opacity {
                NumberAnimation { duration: UI.Style.hoverDuration }
            }
        }
    }

    function open(place, inNewTab) {
        if (place.kind === "drive" && place.url.toString().length === 0) {
            if (inNewTab) {
                view.newTab("neat:computer");
            }
            view.folder.openDrive(place.udi);
            return;
        }
        if (inNewTab) {
            view.newTab(place.url);
        } else {
            folder.openUrl(place.url);
            view.focusContent();
        }
    }
}
