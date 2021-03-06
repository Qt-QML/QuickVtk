import QtQuick 2.12

import Utils 1.0 as Utils
import UI 1.0 as UI

Item {
  id: root;

  anchors.left: parent ? parent.left : undefined;
  anchors.right: parent ? parent.right : undefined;

  property var file: null;
  property bool selected: false;
  property string title: "";
  default property alias content: contentColumn.children;

  height: contentColumn.height;

  Column {
    id: contentColumn;

    anchors.top: parent.top;
    anchors.left: parent.left;
    anchors.right: parent.right;

    spacing: 8;
  }

  onSelectedChanged: {
    if (selected) {
      root.visible = root.enabled = true;
      root.parent = controls;
    } else {
      root.visible = root.enabled = false;
      root.parent = null;
    }
  }

  onFileChanged: {
    if (file) {
      root.selected = Qt.binding (function() { return file.selected; });
    }
  }

  Component.onCompleted: {
    this.file = App.document.file;
    root.parent = controls;
  }
}
