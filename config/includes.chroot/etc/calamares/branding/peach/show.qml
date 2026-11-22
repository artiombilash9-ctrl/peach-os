/* Presentazione dell'installatore Peach OS */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    Timer {
        interval: 20000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: background
            source: "slide1.png"
            width: 540; height: 304
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background.horizontalCenter
            anchors.top: background.bottom
            text: qsTr("Benvenuto in Peach OS.<br/>" +
                  "L'installazione è guidata e termina in pochi minuti.<br/>" +
                  "I pacchetti provengono dai repository Debian.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
        }
    }
}
