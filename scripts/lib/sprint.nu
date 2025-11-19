use api.nu [request-platform]
use logger.nu [log log-success log-error]

# TODO:
# add `--group-by`

export def get_active [] {
    let config = get_config
    
    log "Fetching current active sprint..."

    let sprints = request-platform $config $"/board/($config.board_id)/sprint?state=active"
    let sprint = $sprints | get values.0?

    if ($sprint == null) {
        log-error "Error: No active sprint found"
        exit 1
    }

    log-success $"Found active sprint: ($sprint | get name) \(id: ($sprint | get id)\)"

    $sprint
}

export def get_by_id [sprint_id: int] {
    let config = get_config
    
    log $"Fetching sprint ($sprint_id)..."

    request-platform $config $"/sprint/($sprint_id)"
}

export def get_issues [sprint_id: int, --status: string] {
    let config = get_config

    log $"Fetching issues for sprint ($sprint_id)..."

    let endpoint = $"/board/($config.board_id)/sprint/($sprint_id)/issue?maxResults=100&fields=summary,assignee,status,parent"
    let issues = request-platform $config $endpoint

    let filtered_issues = if $status != null {
        $issues | get issues | where $it.fields.status.name == $status
    } else {
        $issues | get issues | where $it.fields.status.name == "Done"
    }

    log $"Found ($filtered_issues | length) issues."

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

export def list [--state: string = "all"] {
    let config = get_config
    
    let endpoint = if $state == "all" {
        $"/board/($config.board_id)/sprint"
    } else {
        $"/board/($config.board_id)/sprint?state=($state)"
    }
    
    request-platform $config $endpoint
}

export def get_report [sprint_id: int] {
    let config = get_config
    
    let endpoint = $"/board/($config.board_id)/sprint/($sprint_id)/issue?maxResults=100&fields=status"
    let issues = request-platform $config $endpoint
    
    $issues
    | get issues
    | group-by { |it| $it.fields.status.name }
    | items { |status, issues|
        {status: $status, count: ($issues | length)}
    }
}
