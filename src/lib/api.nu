export def request [config: record, endpoint: string] {
    let url = $"($config.url)/rest/agile/1.0($endpoint)"

    try {
        http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
    } catch {
        print --stderr $"(ansi red)Error: Failed to fetch data from Jira API(ansi reset)"
        print --stderr $"URL: ($url)"
        exit 1
    }
}
