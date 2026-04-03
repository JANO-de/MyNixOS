import { App, Astal, Gtk } from "astal/gtk3"

const HuntBar = () => (
    <window
        name="bar" // Este nombre debe coincidir con el 'match' de Niri
        className="Bar"
        namespace="metal-bar"
        // Los anclajes son vitales para que Niri sepa dónde poner la barra
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        // EXCLUSIVE hace que las ventanas de Niri no se solapen con la barra
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        layer={Astal.Layer.TOP}
        visible={true}>
        <centerbox css="background-color: #14140f; border-bottom: 2px solid #ccaa44; padding: 6px;">
            <label label=" ᛟ HUNT: NIRI " css="color: #ccaa44; font-weight: bold;" />
            <label label="Searching for Clues..." css="color: #eee;" />
            <label label="System Ready " css="color: #ccaa44;" />
        </centerbox>
    </window>
)

App.start({
    main: HuntBar,
})