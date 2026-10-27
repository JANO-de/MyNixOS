use gtk4::prelude::*;

fn main() {
    let app = libadwaita::Application::builder()
        .application_id("dev.jano.nixscout")
        .build();
    app.connect_activate(|app| {
        let window = libadwaita::ApplicationWindow::builder()
            .application(app)
            .title("nixscout")
            .default_width(900)
            .default_height(680)
            .build();
        window.present();
    });
    app.run();
}
