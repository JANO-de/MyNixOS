// ~/.config/ags/app.js
import { App, Astal, Gtk, Gdk } from "astal/gtk3"

const HuntBar = () => (
    <window
        name="bar"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}>
        <centerbox css="background-color: #14140f; border-bottom: 2px solid #ccaa44; padding: 4px;">
            <label 
                halign={Gtk.Align.START} 
                label=" ᛟ HUNT: NIXOS " 
                css="color: #ccaa44; font-weight: bold;" 
            />
            <label 
                label="The Bayou is loading..." 
                css="color: #eee;"
            />
            <label 
                halign={Gtk.Align.END} 
                label="System Ready " 
                css="color: #ccaa44;"
            />
        </centerbox>
    </window>
)

App.start({
    main: HuntBar,
})