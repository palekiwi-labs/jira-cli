use logger.nu [log-error]

export def request [config: record, endpoint: string] {
    let url = $"($config.url)/rest/agile/1.0($endpoint)"

    try {
        http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
    } catch {
        log-error "Error: Failed to fetch data from Jira API"
        log-error $"URL: ($url)"
        exit 1
    }
}
