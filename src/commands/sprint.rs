use clap::{Args as ClapArgs, Subcommand};
use anyhow::{Result};
use serde_json::Value;

use crate::api::{Api, SprintParams};
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

    #[arg(short, long)]
    state: Option<String>,

    #[arg(long)]
    max_results: Option<u32>,
}

pub async fn handle(config: Config, args: Args) -> Result<Value> {
    let api = Api::from_config(config);

    match args.command {
        Commands::List(list_args) => list(api, list_args).await,
        Commands::View(view_args) => view(api, view_args).await,
    }
}

async fn list(api: Api, args: ListArgs) -> Result<Value> {
    let params = SprintParams::new(args.state, args.max_results, None);
    let response = api.get_sprint(args.board_id, params).await?;

    Ok(serde_json::to_value(response)?)
}

async fn view(_api: Api, args: ViewArgs) -> Result<Value> {
    Ok(serde_json::json!({"message": format!("dummy view result for board: {}", args.board_id)}))
}
