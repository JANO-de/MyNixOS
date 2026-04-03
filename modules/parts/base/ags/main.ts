// ags-config/main.ts
const Utils = await import('resource:///com/github/Aylur/ags/utils.js');
const App = await import('resource:///com/github/Aylur/ags/app.js');

// Leer el JSON (Igual que hacía el wrapper de Noctalia por detrás)
const configPath = App.configDir + '/config.json';
const settings = JSON.parse(Utils.readFile(configPath));

// Ahora puedes usar 'settings.bar.position' en tus widgets
console.log("Cargando posición:", settings.bar.position);

import { MyBar } from './widgets/Bar.js';

export default {
    style: App.configDir + '/style.css',
    windows: [
        MyBar(settings), // Pasamos los settings a los widgets
    ],
};