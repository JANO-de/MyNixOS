use gtk4::prelude::*;
use libadwaita::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

const KINDS: [&str; 5] = ["package", "option", "module", "flake", "tpflake"];
const TITLES: [&str; 5] = ["Packages", "Options", "Modules", "Flakes", "Third-party"];

fn query_items(db: &str, kind: &str, q: &str) -> Vec<(String, String, String)> {
    let mut out = Vec::new();
    let conn = match rusqlite::Connection::open(db) { Ok(c) => c, Err(_) => return out };
    let like = format!("%{}%", q);
    let sql = "SELECT key,title,summary FROM items WHERE kind=?1 AND (key LIKE ?2 OR title LIKE ?2 OR summary LIKE ?2) LIMIT 50";
    if let Ok(mut stmt) = conn.prepare(sql) {
        if let Ok(rows) = stmt.query_map(rusqlite::params![kind, like], |r| {
            Ok((r.get::<_, String>(0)?, r.get::<_, String>(1)?, r.get::<_, String>(2)?))
        }) {
            for r in rows.flatten() { out.push(r); }
        }
    }
    out
}

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

        let db_path = std::env::var("NIXSCOUT_INDEX")
            .unwrap_or_else(|_| "/usr/share/niXscout/index.sqlite".to_string());

        let header = libadwaita::HeaderBar::new();
        let search = gtk4::SearchEntry::new();
        search.set_placeholder_text(Some("Search…"));
        search.set_hexpand(true);
        header.set_title_widget(Some(&search));

        let view_stack = libadwaita::ViewStack::new();
        let mut lists: Vec<gtk4::ListBox> = Vec::new();
        for (i, t) in TITLES.iter().enumerate() {
            let lb = gtk4::ListBox::new();
            lb.add_css_class("boxed-list");
            let sw = gtk4::ScrolledWindow::builder().child(&lb).build();
            view_stack.add_titled(&sw, Some(&format!("p{}", i)), t);
            lists.push(lb);
        }
        let view_switcher = libadwaita::ViewSwitcher::new();
        view_switcher.set_stack(Some(&view_stack));
        header.set_title_widget(Some(&view_switcher));
        // put search in a box below header instead
        let top_box = gtk4::Box::new(gtk4::Orientation::Vertical, 0);
        top_box.append(&header);
        top_box.append(&search);

        let current: Rc<RefCell<usize>> = Rc::new(RefCell::new(0));
        let refresh = {
            let db = db_path.clone();
            let lists = lists.clone();
            let current = current.clone();
            let search = search.clone();
            move || {
                let idx = *current.borrow();
                let kind = KINDS[idx];
                let q = search.text().to_string();
                let items = query_items(&db, kind, &q);
                let lb = &lists[idx];
                while let Some(child) = lb.first_child() { lb.remove(&child); }
                if items.is_empty() {
                    let lbl = gtk4::Label::new(Some("No results"));
                    lbl.add_css_class("dim-label");
                    lb.append(&lbl);
                } else {
                    for (k, title, summary) in items {
                        let row = gtk4::ListBoxRow::new();
                        let box_ = gtk4::Box::new(gtk4::Orientation::Vertical, 2);
                        let t = gtk4::Label::new(Some(&format!("{} — {}", k, title)));
                        t.set_xalign(0.0);
                        t.add_css_class("heading");
                        let s = gtk4::Label::new(Some(&summary));
                        s.set_xalign(0.0);
                        s.set_wrap(true);
                        s.add_css_class("caption");
                        box_.append(&t);
                        box_.append(&s);
                        row.set_child(Some(&box_));
                        lb.append(&row);
                    }
                }
            }
        };

        // wire view stack page changes
        let refresh_clone = refresh.clone();
        let current_clone = current.clone();
        view_stack.connect_visible_child_name_notify(move |vs| {
            if let Some(name) = vs.visible_child_name() {
                if let Some(idx) = name.strip_prefix('p').and_then(|x| x.parse::<usize>().ok()) {
                    *current_clone.borrow_mut() = idx;
                }
            }
            refresh_clone();
        });

        let search_refresh = refresh.clone();
        search.connect_search_changed(move |_| { search_refresh(); });

        // initial
        refresh();

        let content = gtk4::Box::new(gtk4::Orientation::Vertical, 0);
        content.append(&top_box);
        content.append(&view_stack);
        window.set_child(Some(&content));
        window.present();
    });
    app.run();
}
