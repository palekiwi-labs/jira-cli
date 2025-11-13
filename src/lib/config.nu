export def get_config [] {
    {
        board_id: $env.JIRA_BOARD_ID
        email: $env.JIRA_EMAIL
        token: $env.JIRA_TOKEN
        url: $env.JIRA_URL
    }
}
