use crate::commands::{issue, sprint};
use crate::config::get_config;
use clap::{Parser, Subcommand};

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

pub async fn run() {
    let cli = Cli::parse();
    let config = match get_config() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Config error: {}", e);
            std::process::exit(1);
        }
    };

    let result = match cli.command {
        Commands::Issue(args) => issue::handle(config, args).await,
        Commands::Sprint(args) => sprint::handle(config, args).await,
    };

    match result {
        Ok(value) => {
            match serde_json::to_string_pretty(&value) {
                Ok(json) => println!("{}", json),
                Err(e) => {
                    eprintln!("JSON serialization error: {}", e);
                }
            }
        }
        Err(e) => {
            eprintln!("Error: {}", e);
        }
    }
}
