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

pub fn handle(config: Config, args: Args) -> Result<()> {
    match args.command {
        Commands::View(view_args) => {
            println!("Looking for issue with id {:?} for board {}", view_args.id, config.board_id);

            Ok(())
        }
    }
}
