import QtQuick
import Neat.UI as UI

// An app's icon by theme name or file path (Windows apps keep theirs as a
// file), with the plain process icon when it has none.
UI.ThemeIcon {
    property string icon

    name: icon.length > 0 ? icon : "neat-process"
    fallback: "neat-process"
}
