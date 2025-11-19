use anyhow::{Result};
use clap::{Args as ClapArgs, Subcommand};

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

    let issue: serde_json::Value = response.json().await?;
    println!("{}", serde_json::to_string_pretty(&issue)?);

    Ok(())
}
