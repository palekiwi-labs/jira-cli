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

pub fn run() -> Result<()> {
    let cli = Cli::parse();
    let config = get_config()?;

    match cli.command {
        Commands::Issue(args) => issue::handle(config, args),
        Commands::Sprint(args) => sprint::handle(config, args),
    }
}
