use anyhow::{Result};
use clap::{Args as ClapArgs, Subcommand};
use serde::Deserialize;

use crate::config::Config;

#[derive(ClapArgs)]
pub struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    View(ViewArgs),
}

#[derive(ClapArgs)]
struct ViewArgs {
    key: Option<String>,
}

#[derive(Deserialize, Debug)]
struct JiraIssue {
    id: String,
    key: String,
}

pub async fn handle(config: Config, args: Args) -> Result<()> {
    match args.command {
        Commands::View(view_args) => view_issue(config, view_args).await
    }
}

async fn view_issue(config: Config, args: ViewArgs) -> Result<()> {
    let client = reqwest::Client::builder()
        .user_agent("jira-cli/0.1.0")
        .build()?;

    let url = format!(
        "{}/rest/api/3/issue/{}",
        config.url,
        args.key.unwrap_or(String::from(""))
    );

    let response = client
        .get(&url)
        .basic_auth(&config.email, Some(&config.token))
        .send()
        .await?;

    let issue: JiraIssue = response.json().await?;
    println!("Issue id: {}, issue key: {}", issue.id, issue.key);

    Ok(())
}
