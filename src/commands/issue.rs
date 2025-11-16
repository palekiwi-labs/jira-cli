use clap::{Args as ClapArgs, Subcommand};
use anyhow::{Result};

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
    id: Option<u16>,
}

pub async fn handle(config: Config, args: Args) -> Result<()> {
    match args.command {
        Commands::View(view_args) => view_issue(config, view_args).await
    }
}

async fn view_issue(config: Config, args: ViewArgs) -> Result<()> {
    println!("Looking for issue with id {:?} for board {}", args.id, config.board_id);
    Ok(())
}
