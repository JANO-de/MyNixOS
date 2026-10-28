use std::fs::File;
use std::io::{BufReader, Read};
use rusqlite::{Connection, params};
use serde_json::Value;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let data_dir = args.get(1).map(String::as_str).unwrap_or("data");
    let db_path = args.get(2).map(String::as_str).unwrap_or("index.sqlite");

    // remove existing
    let _ = std::fs::remove_file(db_path);
    let conn = Connection::open(db_path).expect("open db");
    let schema = include_str!("schema.sql");
    conn.execute_batch(schema).expect("schema");

    // read packages.json (plain or brotli)
    let pkg_file = format!("{}/packages.json", data_dir);
    let alt = format!("{}/packages.json.br", data_dir);
    let reader: Box<dyn Read> = if std::path::Path::new(&pkg_file).exists() {
        Box::new(BufReader::new(File::open(&pkg_file).unwrap()))
    } else if std::path::Path::new(&alt).exists() {
        let f = File::open(&alt).unwrap();
        Box::new(brotli::Decompressor::new(BufReader::new(f), 4096))
    } else {
        eprintln!("no packages.json found in {}", data_dir);
        return;
    };

    let v: Value = serde_json::from_reader(reader).expect("parse json");
    if let Some(pkgs) = v.get("packages").and_then(|x| x.as_object()) {
        let mut stmt = conn.prepare("INSERT INTO items(kind,key,title,summary,version,flags) VALUES (?1,?2,?3,?4,?5,0)").unwrap();
        let mut n = 0;
        for (attr, info) in pkgs {
            let pname = info.get("pname").and_then(|x| x.as_str()).unwrap_or(attr);
            let version = info.get("version").and_then(|x| x.as_str()).unwrap_or("");
            let desc = info.get("description").and_then(|x| x.as_str()).unwrap_or("");
            stmt.execute(params!["package", attr, pname, desc, version]).unwrap();
            let id = conn.last_insert_rowid();
            conn.execute("INSERT INTO items_fts(rowid,key,title,summary) VALUES (?1,?2,?3,?4)", params![id, attr, pname, desc]).unwrap();
            n += 1;
        }
        println!("indexed {} packages", n);
    }

    conn.execute("INSERT INTO meta(key,value) VALUES ('schema_version','1')", []).unwrap();
}
