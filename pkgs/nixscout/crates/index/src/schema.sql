CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY,
  kind TEXT NOT NULL,
  key TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT,
  version TEXT,
  flags INTEGER NOT NULL DEFAULT 0
);
CREATE VIRTUAL TABLE IF NOT EXISTS items_fts USING fts5(key, title, summary, content='items', content_rowid='id', prefix='2 3');
CREATE TABLE IF NOT EXISTS details (
  id INTEGER PRIMARY KEY,
  json TEXT NOT NULL,
  FOREIGN KEY(id) REFERENCES items(id)
);
CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
