// Third-party fetchers (runtime). Network happens only when the tab is opened.
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Record {
    pub id: String,
    pub title: String,
    pub summary: String,
    pub url: String,
    pub stars: Option<u64>,
    pub updated: Option<String>,
}

pub trait Source {
    fn name(&self) -> &'static str;
    fn fetch(&self) -> Result<Vec<Record>, String>;
}

pub struct GithubTopic;
impl Source for GithubTopic {
    fn name(&self) -> &'static str { "github-topic" }
    fn fetch(&self) -> Result<Vec<Record>, String> { Ok(vec![]) }
}

pub struct FlakeHub;
impl Source for FlakeHub {
    fn name(&self) -> &'static str { "flakehub" }
    fn fetch(&self) -> Result<Vec<Record>, String> { Ok(vec![]) }
}

pub fn version() -> &'static str { "0.1.0" }
