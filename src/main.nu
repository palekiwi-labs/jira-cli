#!/usr/bin/env nu

def main [
    sprint_id?: int 
    --quiet(-q)
] {
    # Configuration - Read from environment variables
    let config = {
        url: $env.JIRA_URL
        email: $env.JIRA_EMAIL
        token: $env.JIRA_TOKEN
        board_id: $env.JIRA_BOARD_ID
    }

    let sprint = if $sprint_id != null {
        get_sprint_by_id --quiet=$quiet $config $sprint_id
    } else {
        get_current_sprint --quiet=$quiet $config
    }
    fetch_done_issues --quiet=$quiet $config $sprint
}

# Make authenticated request to Jira API
def jira_request [ config: record, endpoint: string ] {
    let url = $"($config.url)/rest/agile/1.0($endpoint)"

    # TODO: This should return an error in the response
    try {
        http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
    } catch {                                                                                        
        print --stderr $"(ansi red)Error: Failed to fetch data from Jira API(ansi reset)"            
        print --stderr $"URL: ($url)"                                                                
        exit 1                                                                                       
    }
}

# Get current active sprint
def get_current_sprint [ config: record, --quiet ] {
    if not $quiet {
        print $"(ansi default)Fetching current active sprint...(ansi reset)"
    }

    let sprints = jira_request $config $"/board/($config.board_id)/sprint?state=active"
    let sprint = $sprints | get values.0?

    if ($sprint == null) {                                                                            
         print --stderr $"(ansi red)Error: No active sprint found(ansi reset)"                            
         exit 1                                                                                           
    }

    if not $quiet {
        print $"(ansi green)Found active sprint: ($sprint | get name) \(id: ($sprint | get id)\)(ansi reset)"
    }

    $sprint
}

# # Get sprint ID by number
def get_sprint_by_id [
    config: record
    sprint_id: int
    --quiet
] {
    if not $quiet { print $"(ansi default)Fetching sprint ($sprint_id)...(ansi reset)" }

    jira_request $config $"/sprint/($sprint_id)"
}

# Fetch and format issues
def fetch_done_issues [
    config: record
    sprint: record
    --quiet
] {
    let sprint_id = $sprint.id

    if not $quiet { print $"(ansi default)Fetching done issues for sprint ($sprint_id)...(ansi reset)" }

    let endpoint = $"/board/($config.board_id)/sprint/($sprint_id)/issue?maxResults=100&fields=summary,assignee,status,parent"
    let issues = jira_request $config $endpoint

    let issues = $issues | get issues | where $it.fields.status.name == "Done"

    if not $quiet { print $"(ansi default)Found ($issues | length) issues.(ansi reset)" }

    $issues
    | group-by { |it| $it.fields.parent?.fields?.summary? | default "" }
    | items { |parent_name, issues|
        if $parent_name != "" {
            [
                $"\n[($parent_name)]"
                ...($issues | each { |issue|
                    let assignee = $issue.fields.assignee?.displayName? | default "Unassigned"
                    $"* ($issue.fields.summary) \(($assignee))"
                })
            ]
        } else {
            [
                $"\n[Misc]"
                ...($issues | each { |issue|
                    let assignee = $issue.fields.assignee?.displayName? | default "Unassigned"
                    $"* ($issue.fields.summary) \(($assignee))"
                })
            ]
        }
    }
    | flatten
    | str join "\n"
}
