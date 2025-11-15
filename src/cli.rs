use clap::{Args, Parser, Subcommand};

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
    Issue(IssueArgs),
    Sprint(SprintArgs),
}

#[derive(Args)]
struct SprintArgs {
    #[command(subcommand)]
    command: SprintCommands,
}

#[derive(Subcommand)]
enum SprintCommands {
    View(SprintViewArgs)
}

#[derive(Args, Clone)]
struct SprintViewArgs {
    id: Option<u16>
}

#[derive(Args)]
struct IssueArgs {}

pub fn run() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Issue(_) => println!("TODO"),
        Commands::Sprint(args) => {
            match &args.command {
                SprintCommands::View(view_args) => {
                    println!("Looking for sprint with id: {:?}", view_args.id)
                }
            }
        }
    }
}

