export def get_current_sprint [--quiet] {
    let config = get_config
    
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

export def get_sprint_by_id [
    sprint_id: int
    --quiet
] {
    let config = get_config
    
    if not $quiet {
        print $"(ansi default)Fetching sprint ($sprint_id)...(ansi reset)"
    }

    jira_request $config $"/sprint/($sprint_id)"
}

export def get_sprint_issues [
    sprint_id: int
    --status: string
    --quiet
] {
    let config = get_config

    if not $quiet {
        print $"(ansi default)Fetching issues for sprint ($sprint_id)...(ansi reset)"
    }

    let endpoint = $"/board/($config.board_id)/sprint/($sprint_id)/issue?maxResults=100&fields=summary,assignee,status,parent"
    let issues = jira_request $config $endpoint

    let filtered_issues = if $status != null {
        $issues | get issues | where $it.fields.status.name == $status
    } else {
        $issues | get issues | where $it.fields.status.name == "Done"
    }

    if not $quiet {
        print $"(ansi default)Found ($filtered_issues | length) issues.(ansi reset)"
    }

    $filtered_issues
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

export def list_sprints [--state: string = "all"] {
    let config = get_config
    
    let endpoint = if $state == "all" {
        $"/board/($config.board_id)/sprint"
    } else {
        $"/board/($config.board_id)/sprint?state=($state)"
    }
    
    jira_request $config $endpoint
}

export def get_sprint_report [sprint_id: int] {
    let config = get_config
    
    let endpoint = $"/board/($config.board_id)/sprint/($sprint_id)/issue?maxResults=100&fields=status"
    let issues = jira_request $config $endpoint
    
    $issues
    | get issues
    | group-by { |it| $it.fields.status.name }
    | items { |status, issues|
        {status: $status, count: ($issues | length)}
    }
}
