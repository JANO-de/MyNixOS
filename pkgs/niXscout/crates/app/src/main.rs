use gtk4::prelude::*;
use libadwaita::prelude::*;
use std::env;

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

        let db_path = env::var("NIXSCOUT_INDEX").unwrap_or_else(|_| "/usr/share/niXscout/index.sqlite".to_string());
        let count: i64 = (|| {
            let conn = rusqlite::Connection::open(&db_path).ok()?;
            conn.query_row("SELECT COUNT(*) FROM items", [], |r| r.get(0)).ok()
        })().unwrap_or(0);

        let label = gtk4::Label::new(Some(&format!("niXscout — {} items indexed", count)));
        window.set_child(Some(&label));
        window.present();
    });
    app.run();
}
