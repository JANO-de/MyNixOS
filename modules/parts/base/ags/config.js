// Un ejemplo ultra-básico para confirmar que funciona
const App = await import('resource:///com/github/Aylur/ags/app.js');
const Widget = await import('resource:///com/github/Aylur/ags/widget.js');

const Bar = (monitor = 0) => Widget.Window({
    monitor,
    name: `bar-${monitor}`,
    anchor: ['top', 'left', 'right'],
    exclusivity: 'exclusive',
    child: Widget.CenterBox({
        start_widget: Widget.Label('Hunt Showdown OS'),
        center_widget: Widget.Label({ label: 'Bayou Shell' }),
        end_widget: Widget.Label({
            setup: self => self.poll(1000, label => {
                label.label = new Date().toLocaleTimeString();
            }),
        }),
    }),
});

export default { windows: [ Bar() ] };