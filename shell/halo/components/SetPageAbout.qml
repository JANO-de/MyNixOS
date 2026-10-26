import QtQuick
import qs.services

// Settings > About: device and software facts.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Info.refresh()

    SetGroup {
        SetRow { title: "Device name"; subtitle: Info.get("host"); tappable: false }
        SetRow { title: "Model"; subtitle: Info.get("model"); tappable: false }
    }

    SetGroup {
        title: "Software information"
        SetRow { title: "Halo version"; subtitle: Info.haloVersion; tappable: false }
        SetRow { title: "System"; subtitle: Info.get("os") + " (" + Info.get("nixver") + ")"; tappable: false }
        SetRow { title: "Kernel version"; subtitle: Info.get("kernel"); tappable: false }
    }

    SetGroup {
        title: "Hardware"
        SetRow { title: "Processor"; subtitle: Info.get("cpu"); tappable: false }
        SetRow { title: "Memory"; subtitle: Info.kv["memtotal"] ? Info.gb(parseFloat(Info.kv["memtotal"])) : "-"; tappable: false }
        SetRow { title: "Uptime"; subtitle: Info.get("uptime"); tappable: false }
    }
}
