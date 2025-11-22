use anyhow::{bail, Result};
use reqwest::Client;
use serde_json::Value;

use crate::config::Config;

pub struct Api {
    client: Client,
    email: String,
    token: String,
    base_url: String,
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

    pub async fn get_sprint(&self, board_id: u32) -> Result<Value> {
        let url = format!(
            "{}/rest/agile/1.0/board/{}/sprint",
            self.base_url,
            board_id
        );

        let response = self.client
            .get(&url)
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
