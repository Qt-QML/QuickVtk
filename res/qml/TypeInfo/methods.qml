import QtQuick 2.12

import UI 1.0 as UI

UI.List {
  title: "Methods";
  property var symbol;
  visible: _rep.model != undefined && _rep.model.length > 0;

  Repeater {
    id: _rep;

    model: symbol ? symbol.methods : null;

    delegate: Item {
      anchors.left: parent.left;
      anchors.right: parent.right;

      height: _name.height;

      Tag {
        id: _ic;

        anchors.left: parent.left;
        anchors.verticalCenter: parent.verticalCenter;

        label.text: "M";
        label.color: "#2BA468";
      }

      UI.Badge {
        id: _base;

        visible: modelData.inherited;

        anchors.left: _ic.right;
        anchors.leftMargin: 8;
        anchors.verticalCenter: parent.verticalCenter;

        label.text: "base";
        color: "#21252B";
      }

      Row {
        anchors.left: modelData.inherited ? _base.right : _ic.right;
        anchors.verticalCenter: parent.verticalCenter;

        UI.Label {
          id: _name;

          anchors.verticalCenter: parent.verticalCenter;

          leftPadding: 8;

          font.pointSize: 13;
          text: modelData.name + " (";
          color: "#fff";
        }

        UI.Label {
          anchors.verticalCenter: parent.verticalCenter;

          font.pointSize: 13;
          rightPadding: 2;
          leftPadding: 2;
          text: modelData.paramTypes;
        }

        UI.Label {
          anchors.verticalCenter: parent.verticalCenter;

          font.pointSize: 13;
          text: ")";
          color: "#fff";
        }

        UI.Icon {
          anchors.verticalCenter: parent.verticalCenter;
          rightPadding: 8;
          leftPadding: 8;

          icon: icons.fa_long_arrow_right;
          color: "#fff";
        }

        UI.Label {
          anchors.verticalCenter: parent.verticalCenter;

          font.pointSize: 13;
          text: modelData.returnType;
        }
      }
    }
  }
}
