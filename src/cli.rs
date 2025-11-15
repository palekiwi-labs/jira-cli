use clap::{Parser, Subcommand};
use crate::commands::{sprint, issue};

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

pub fn run() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Issue(args) => issue::handle(args),
        Commands::Sprint(args) => sprint::handle(args),
    }
}

