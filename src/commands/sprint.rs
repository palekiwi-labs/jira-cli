use clap::{Args as ClapArgs, Subcommand};
use anyhow::{Result};
use serde_json::Value;

use crate::config::Config;

#[derive(ClapArgs)]
pub struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    List(ListArgs),
    View(ViewArgs),
}

#[derive(ClapArgs)]
struct ViewArgs {
    #[arg(long, env = "JIRA_BOARD_ID")]
    board_id: u32,

    id: Option<u16>,

}

#[derive(ClapArgs)]
struct ListArgs {
    #[arg(long, env = "JIRA_BOARD_ID")]
    board_id: u32,
}

pub async fn handle(_config: Config, args: Args) -> Result<Value> {
    match args.command {
        Commands::List(list_args) => list(list_args).await,
        Commands::View(view_args) => view(view_args).await,
    }
}

async fn list(args: ListArgs) -> Result<Value> {
    Ok(serde_json::json!({"message": format!("dummy list result for board: {}", args.board_id)}))
}

async fn view(args: ViewArgs) -> Result<Value> {
    Ok(serde_json::json!({"message": format!("dummy view result for board: {}", args.board_id)}))
}
