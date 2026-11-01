pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Device facts for Settings > Storage / Updates / About. One shell script, key=value lines; refresh() reruns it.
Singleton {
    id: root

    property var kv: ({})
    property var gens: [] // { name, date, target }, newest first
    readonly property string haloVersion: "Halo 0.1 (Quickshell + Hyprland)"

    function refresh() {
        if (proc.running)
            return;
        proc.running = true;
    }

    function get(k) {
        return kv[k] !== undefined && kv[k] !== "" ? kv[k] : "-";
    }

    // "size used avail" in bytes (df output) -> { size, used, avail }
    function disk(k) {
        const f = String(kv[k] || "").trim().split(/\s+/).map(x => parseFloat(x));
        if (f.length < 3 || isNaN(f[0]))
            return { size: 0, used: 0, avail: 0 };
        return { size: f[0], used: f[1], avail: f[2] };
    }

    function gb(bytes) {
        const g = bytes / 1073741824;
        return (g >= 100 ? g.toFixed(0) : g.toFixed(1)) + " GB";
    }

    Process {
        id: proc
        command: ["sh", "-c", [
            "echo \"host=$(hostname)\"",
            "echo \"model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)\"",
            "echo \"os=$(. /etc/os-release 2>/dev/null; echo $PRETTY_NAME)\"",
            "echo \"nixver=$(nixos-version 2>/dev/null)\"",
            "echo \"kernel=$(uname -r)\"",
            "echo \"uptime=$(uptime -p 2>/dev/null)\"",
            "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')\"",
            "echo \"memtotal=$(awk '/MemTotal/{print $2*1024}' /proc/meminfo)\"",
            "echo \"memavail=$(awk '/MemAvailable/{print $2*1024}' /proc/meminfo)\"",
            "echo \"root=$(df -B1 --output=size,used,avail / | tail -n1)\"",
            "echo \"home=$(df -B1 --output=size,used,avail \"$HOME\" | tail -n1)\"",
            "echo \"gen=$(readlink /nix/var/nix/profiles/system)\"",
            "for g in $(ls -1 /nix/var/nix/profiles 2>/dev/null | grep '^system-[0-9]*-link$' | sort -t- -k2 -n | tail -8); do echo \"G|$g|$(stat -c %y /nix/var/nix/profiles/$g | cut -d. -f1)|$(readlink /nix/var/nix/profiles/$g)\"; done"
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const kv = {};
                const gens = [];
                for (const line of text.split("\n")) {
                    if (line.indexOf("G|") === 0) {
                        const f = line.split("|");
                        gens.push({ name: f[1], date: f[2], target: f[3] });
                        continue;
                    }
                    const i = line.indexOf("=");
                    if (i > 0)
                        kv[line.substring(0, i)] = line.substring(i + 1);
                }
                gens.reverse();
                root.kv = kv;
                root.gens = gens;
            }
        }
    }
}
