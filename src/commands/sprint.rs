use clap::{Args as ClapArgs, Subcommand};
use anyhow::{Result};
use serde_json::Value;

use crate::api::{Api, SprintParams, SprintIssuesParams};
use crate::config::Config;

#[derive(ClapArgs)]
pub struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Issues(IssuesArgs),
    List(ListArgs),
    View(ViewArgs),
}

#[derive(ClapArgs)]
struct ViewArgs {
    id: u32,
}

#[derive(ClapArgs)]
struct IssuesArgs {
    #[arg(long, env = "JIRA_BOARD_ID")]
    board_id: u32,

    #[arg(long)]
    sprint_id: u32,

    #[arg(long)]
    start_at: Option<u32>,

    #[arg(long)]
    max_results: Option<u32>,

    #[arg(long)]
    jql: Option<String>,

    #[arg(long)]
    validate_query: Option<bool>,

    #[arg(long)]
    fields: Option<String>,

    #[arg(long)]
    expand: Option<String>,
}

#[derive(ClapArgs)]
struct ListArgs {
    #[arg(long, env = "JIRA_BOARD_ID")]
    board_id: u32,

    #[arg(short, long)]
    state: Option<String>,

    #[arg(long)]
    max_results: Option<u32>,

    #[arg(long)]
    start_at: Option<u32>,
}

pub async fn handle(config: Config, args: Args) -> Result<Value> {
    let api = Api::from_config(config);

    match args.command {
        Commands::Issues(issues_args) => issues(api, issues_args).await,
        Commands::List(list_args) => list(api, list_args).await,
        Commands::View(view_args) => view(api, view_args).await,
    }
}

async fn list(api: Api, args: ListArgs) -> Result<Value> {
    let params = SprintParams::new(args.state, args.max_results, args.start_at);
    let response = api.get_board_sprints(args.board_id, params).await?;

    Ok(serde_json::to_value(response)?)
}

async fn view(api: Api, args: ViewArgs) -> Result<Value> {
    let sprint = api.get_sprint_by_id(args.id).await?;
    Ok(serde_json::to_value(sprint)?)
}

async fn issues(api: Api, args: IssuesArgs) -> Result<Value> {
    let params = SprintIssuesParams::new(
        args.start_at,
        args.max_results,
        args.jql,
        args.validate_query,
        args.fields,
        args.expand,
    );
    let response = api.get_sprint_issues(args.board_id, args.sprint_id, params).await?;
    Ok(serde_json::to_value(response)?)
}
