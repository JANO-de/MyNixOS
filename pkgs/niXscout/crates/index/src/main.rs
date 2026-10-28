use std::collections::BTreeMap;
use std::fs::File;
use std::io::{BufReader, Read};
use rusqlite::{Connection, params};
use serde_json::Value;

fn open_reader(path: &str) -> Option<Box<dyn Read>> {
    if std::path::Path::new(path).exists() {
        let f = File::open(path).ok()?;
        if path.ends_with(".br") {
            Some(Box::new(brotli::Decompressor::new(BufReader::new(f), 4096)))
        } else {
            Some(Box::new(BufReader::new(f)))
        }
    } else {
        None
    }
}

fn read_json(path: &str) -> Option<Value> {
    let r = open_reader(path)?;
    serde_json::from_reader(r).ok()
}

fn insert_item(conn: &Connection, kind: &str, key: &str, title: &str, summary: &str, version: &str, details: &str) {
    conn.execute(
        "INSERT INTO items(kind,key,title,summary,version,flags) VALUES (?1,?2,?3,?4,?5,0)",
        params![kind, key, title, summary, version],
    ).unwrap();
    let id = conn.last_insert_rowid();
    conn.execute(
        "INSERT INTO items_fts(rowid,key,title,summary) VALUES (?1,?2,?3,?4)",
        params![id, key, title, summary],
    ).unwrap();
    conn.execute(
        "INSERT INTO details(id,json) VALUES (?1,?2)",
        params![id, details],
    ).unwrap();
}

fn parse_packages(conn: &Connection, data_dir: &str) -> usize {
    let mut n = 0;
    for name in ["packages.json", "packages.json.br"] {
        let path = format!("{}/{}", data_dir, name);
        if let Some(v) = read_json(&path) {
            if let Some(obj) = v.get("packages").and_then(|x| x.as_object()) {
                for (attr, info) in obj {
                    let pname = info.get("pname").and_then(|x| x.as_str()).unwrap_or(attr);
                    let version = info.get("version").and_then(|x| x.as_str()).unwrap_or("");
                    let desc = info.get("description").and_then(|x| x.as_str()).unwrap_or("");
                    let details = serde_json::to_string(info).unwrap_or_else(|_| "{}".to_string());
                    insert_item(conn, "package", attr, pname, desc, version, &details);
                    n += 1;
                }
            }
            break;
        }
    }
    n
}

fn derive_modules(conn: &Connection, opts: &[(String, Value)]) -> usize {
    // group options by first two path segments
    let mut groups: BTreeMap<String, Vec<(String, Value)>> = BTreeMap::new();
    for (key, info) in opts {
        let segs: Vec<&str> = key.split('.').collect();
        let modname = if segs.len() >= 2 {
            format!("{}.{}", segs[0], segs[1])
        } else {
            segs[0].to_string()
        };
        groups.entry(modname).or_default().push((key.clone(), info.clone()));
    }
    let mut n = 0;
    for (modname, members) in groups {
        let count = members.len();
        let enable_key = format!("{}.enable", modname);
        let has_enable = members.iter().any(|(k, _)| k == &enable_key);
        let file = members.iter()
            .filter_map(|(_, info)| info.get("declarations").and_then(|d| d.as_array()).and_then(|a| a.first()).and_then(|x| x.as_str()))
            .next()
            .unwrap_or("")
            .to_string();
        let details = serde_json::json!({
            "module": modname,
            "enable": has_enable,
            "count": count,
            "file": file,
            "options": members.iter().map(|(k, _)| k.clone()).collect::<Vec<_>>(),
        });
        insert_item(conn, "module", &modname, &modname, &format!("{} options", count), "", &details.to_string());
        n += 1;
    }
    n
}

fn parse_flakes(conn: &Connection, data_dir: &str, lock_path: Option<&str>) -> usize {
    let mut n = 0;
    // registry
    for name in ["flake-registry.json", "flake-registry.json.br"] {
        let path = format!("{}/{}", data_dir, name);
        if let Some(v) = read_json(&path) {
            let flakes = v.get("flakes").and_then(|x| x.as_array()).cloned().unwrap_or_default();
            for f in flakes {
                let attr = f.get("attr").or_else(|| f.get("name")).and_then(|x| x.as_str()).unwrap_or("");
                if attr.is_empty() { continue; }
                let desc = f.get("description").and_then(|x| x.as_str()).unwrap_or("");
                let url = f.get("url").or_else(|| f.get("repo")).and_then(|x| x.as_str()).unwrap_or("");
                let details = serde_json::json!({"attr": attr, "url": url, "raw": f});
                insert_item(conn, "flake", attr, attr, desc, "", &details.to_string());
                n += 1;
            }
            break;
        }
    }
    // flake.lock root inputs
    if let Some(lp) = lock_path {
        if let Some(v) = read_json(lp) {
            if let Some(nodes) = v.get("nodes").and_then(|x| x.as_object()) {
                if let Some(root) = nodes.get("root") {
                    if let Some(inputs) = root.get("inputs").and_then(|x| x.as_object()) {
                        for (name, val) in inputs {
                            let node_key = val.as_str().unwrap_or("");
                            let (owner, repo, rev, lastmod) = if let Some(node) = nodes.get(node_key) {
                                let locked = node.get("locked");
                                let owner = locked.and_then(|l| l.get("owner")).and_then(|x| x.as_str()).unwrap_or("");
                                let repo = locked.and_then(|l| l.get("repo")).and_then(|x| x.as_str()).unwrap_or("");
                                let rev = locked.and_then(|l| l.get("rev")).and_then(|x| x.as_str()).unwrap_or("");
                                let lm = locked.and_then(|l| l.get("lastModified")).and_then(|x| x.as_i64()).unwrap_or(0);
                                (owner, repo, rev, lm)
                            } else {
                                ("", "", "", 0i64)
                            };
                            let key = format!("lock:{}", name);
                            let title = if owner.is_empty() { name.clone() } else { format!("{}/{}", owner, repo) };
                            let details = serde_json::json!({
                                "input": name,
                                "owner": owner,
                                "repo": repo,
                                "rev": rev,
                                "lastModified": lastmod,
                            });
                            insert_item(conn, "flake", &key, &title, "this repo's flake.lock input", "", &details.to_string());
                            n += 1;
                        }
                    }
                }
            }
        }
    }
    n
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let data_dir = args.get(1).map(String::as_str).unwrap_or("data");
    let db_path = args.get(2).map(String::as_str).unwrap_or("index.sqlite");
    let lock_path = args.get(3).map(String::as_str);

    let _ = std::fs::remove_file(db_path);
    let conn = Connection::open(db_path).expect("open db");
    let schema = include_str!("schema.sql");
    conn.execute_batch(schema).expect("schema");

    // collect option records for module derivation
    let mut all_opts: Vec<(String, Value)> = Vec::new();
    for file in ["options.json", "hm-options.json"] {
        let path = format!("{}/{}", data_dir, file);
        let alt = format!("{}.br", path);
        let p = if std::path::Path::new(&path).exists() { path } else if std::path::Path::new(&alt).exists() { alt } else { continue };
        if let Some(v) = read_json(&p) {
            let items: Vec<(String, Value)> = if let Some(obj) = v.as_object() {
                obj.iter().map(|(k, val)| (k.clone(), val.clone())).collect()
            } else if let Some(arr) = v.as_array() {
                arr.iter().filter_map(|e| {
                    // try common name fields
                    let nm = e.get("name").or_else(|| e.get("option")).or_else(|| e.get("key"))
                        .and_then(|x| x.as_str()).map(String::from)?;
                    Some((nm, e.clone()))
                }).collect()
            } else { Vec::new() };
            let cnt = items.len();
            for (key, info) in &items { all_opts.push((key.clone(), info.clone())); }
            // insert options
            for (key, info) in items {
                let desc = info.get("description").and_then(|x| x.as_str()).unwrap_or("");
                let typ = info.get("type").and_then(|x| x.as_str()).unwrap_or("");
                let default = info.get("default").map(|x| x.to_string()).unwrap_or_default();
                let example = info.get("example").map(|x| x.to_string()).unwrap_or_default();
                let decls = info.get("declarations").cloned().unwrap_or(Value::Array(vec![]));
                let details = serde_json::json!({"type":typ,"default":default,"example":example,"declarations":decls});
                insert_item(&conn, "option", &key, &key, desc, "", &details.to_string());
            }
            eprintln!("indexed {} options from {}", cnt, file);
        }
    }

    let np = parse_packages(&conn, data_dir);
    eprintln!("indexed {} packages", np);

    let nm = derive_modules(&conn, &all_opts);
    eprintln!("derived {} modules", nm);

    let nf = parse_flakes(&conn, data_dir, lock_path);
    eprintln!("indexed {} flakes", nf);

    conn.execute("INSERT INTO meta(key,value) VALUES ('schema_version','1')", []).unwrap();
}
