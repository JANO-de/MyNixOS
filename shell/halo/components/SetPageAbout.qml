import QtQuick
import qs.services

// Settings > About: device and software facts.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Info.refresh()

    SetGroup {
        SetRow { title: "Device"; subtitle: Info.get("model"); tappable: false }
        SetRow { title: "Name"; subtitle: Info.get("host"); tappable: false }
        SetRow { title: "Processor"; subtitle: Info.get("cpu"); tappable: false }
        SetRow { title: "Memory"; subtitle: Info.kv["memtotal"] ? Info.gb(parseFloat(Info.kv["memtotal"])) : "-"; tappable: false }
    }

    SetGroup {
        title: "Software"
        SetRow { title: "Halo"; subtitle: Info.haloVersion; tappable: false }
        SetRow { title: "System"; subtitle: Info.get("os") + " (" + Info.get("nixver") + ")"; tappable: false }
        SetRow { title: "Kernel"; subtitle: Info.get("kernel"); tappable: false }
        SetRow { title: "Up"; subtitle: Info.get("uptime"); tappable: false }
    }
}
