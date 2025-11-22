use anyhow::{bail, Result};
use reqwest::Client;
use serde::Serialize;
use serde_json::Value;

use crate::config::Config;

pub struct Api {
    client: Client,
    email: String,
    token: String,
    base_url: String,
}

#[derive(Serialize)]
pub struct SprintParams {
    state: Option<String>,
    #[serde(rename = "maxResults")]
    max_results: Option<u32>,
    #[serde(rename = "startAt")]
    start_at: Option<u32>,
}

impl SprintParams {
    pub fn new(state: Option<String>, max_results: Option<u32>, start_at: Option<u32>) -> Self {
        SprintParams { state, max_results, start_at }
    }
}

impl Api {
    pub fn from_config(config: Config) -> Api {
        Api {
            client: Client::new(),
            email: config.email,
            token: config.token,
            base_url: config.url,
        }
    }

    pub async fn get_sprint(&self, board_id: u32, params: SprintParams) -> Result<Value> {
        let url = format!(
            "{}/rest/agile/1.0/board/{}/sprint",
            self.base_url,
            board_id
        );

        let response = self.client
            .get(&url)
            .query(&params)
            .header("Accept", "application/json")
            .basic_auth(&self.email, Some(&self.token))
            .send()
            .await?;

        let status = response.status();

        if !status.is_success() {
            bail!("API request failed with status: {} for URL: {}", status, url)
        } else {
            Ok(response.json().await?)
        }
    }
}
