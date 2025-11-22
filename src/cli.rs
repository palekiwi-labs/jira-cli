use crate::commands::{issue, sprint};
use crate::config::get_config;
use clap::{Parser, Subcommand};

use anyhow::{Result};

#[derive(Parser)]
#[command(name = "Jira CLI")]
#[command(version, about)]
#[command(propagate_version = true)]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Issue(issue::Args),
    Sprint(sprint::Args),
}

pub async fn run() -> Result<()> {
    let cli = Cli::parse();
    let config = get_config()?;

    let result = match cli.command {
        Commands::Issue(args) => issue::handle(config, args).await,
        Commands::Sprint(args) => sprint::handle(config, args).await,
    };

    if let Ok(value) = result {
        println!("{}", serde_json::to_string_pretty(&value)?);
    }

    Ok(())
}
