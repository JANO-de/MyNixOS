use gtk4::prelude::*;

fn main() {
    let app = libadwaita::Application::builder()
        .application_id("dev.jano.niXscout")
        .build();
    app.connect_activate(|app| {
        let window = libadwaita::ApplicationWindow::builder()
            .application(app)
            .title("niXscout")
            .default_width(900)
            .default_height(680)
            .build();
        window.present();
    });
    app.run();
}
