use std::fs;
use rusqlite::Connection;

fn main() {
    let db_path = std::env::args().nth(1).unwrap_or_else(|| "index.sqlite".to_string());
    let conn = Connection::open(&db_path).expect("open db");
    let schema = include_str!("schema.sql");
    conn.execute_batch(schema).expect("schema");
    println!("created {}", db_path);
    // placeholder: real indexing parses data/*.json
    let _ = fs::read_dir("data");
}
