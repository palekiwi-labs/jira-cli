use clap::{Args as ClapArgs, Subcommand};

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

pub fn handle(args: Args) {
    match args.command {
        Commands::View(view_args) => {
            println!("Looking for issue with id {:?}:", view_args.id)
        }
    }
}
