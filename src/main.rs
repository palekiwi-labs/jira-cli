#[tokio::main]
async fn main() -> anyhow::Result<()> {
    jira_cli::run().await
}
