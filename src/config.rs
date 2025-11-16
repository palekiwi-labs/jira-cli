use anyhow::{Context, Result};
use std::env;

pub struct Config {
    pub email: String,
    pub token: String,
    pub url: String,
    pub board_id: u32,
}

pub fn get_config() -> Result<Config> {
    Ok(Config {
        email: env::var("JIRA_EMAIL").context("JIRA_EMAIL must be set")?,
        token: env::var("JIRA_TOKEN").context("JIRA_TOKEN must be set")?,
        url: env::var("JIRA_URL").context("JIRA_URL must be set")?,
        board_id: env::var("JIRA_BOARD_ID")
            .context("JIRA_BOARD_ID must be set")?
            .parse()
            .context("JIRA_BOARD_ID must be a number")?,
    })
}
