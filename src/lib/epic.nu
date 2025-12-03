use api.nu [request]
use config.nu [get_config]
use logger.nu [log log-success log-error]

# List all epics from the board
export def list [--done: string] {
    let config = get_config
    
    log "Fetching epics from board..."

    let endpoint = if $done != null {
        $"/board/($config.board_id)/epic?done=($done)"
    } else {
        $"/board/($config.board_id)/epic"
    }
    
    let response = request $config $endpoint
    let epics = $response | get values
    
    log-success $"Found (($epics | length)) epic\(s\)"
    
    $epics
    | select key id name summary done
    | rename issue_key epic_id epic_name epic_summary completed
}

# Get a specific epic by ID
export def get_by_id [epic_id: int] {
    let config = get_config
    
    log $"Fetching epic ($epic_id)..."

    request $config $"/epic/($epic_id)"
}

# Get all issues in an epic
export def get_issues [epic_id: int] {
    let config = get_config

    log $"Fetching issues for epic ($epic_id)..."

    let endpoint = $"/board/($config.board_id)/epic/($epic_id)/issue?maxResults=100&fields=summary,assignee,status"
    let response = request $config $endpoint
    let issues = $response | get issues
    
    log-success $"Found (($issues | length)) issue\(s\) in epic"
    
    $issues
    | select key fields
    | each { |issue|
        {
            key: $issue.key
            summary: $issue.fields.summary
            status: $issue.fields.status.name
            assignee: ($issue.fields.assignee?.displayName? | default "Unassigned")
        }
    }
}
