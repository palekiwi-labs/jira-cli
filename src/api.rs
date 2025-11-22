use anyhow::Result;
use serde_json::Value;

pub struct Client {
    client: reqwest::Client,
    email: String,
    token: String,
}

pub struct Api {
    client: Client,
}

impl Api {
    pub fn get_sprint(board_id: String) -> Result<Value> {
        todo!()
    }
}
