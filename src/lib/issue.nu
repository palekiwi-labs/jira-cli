use config.nu [get_config]
use logger.nu [log log-success log-error]

# Get a specific issue by key (e.g., "PROJ-123")
export def get_by_key [issue_key: string] {
    let config = get_config
    
    log $"Fetching issue ($issue_key)..."

    # Use Platform API v3 for issue details
    let url = $"($config.url)/rest/api/3/issue/($issue_key)"
    
    try {
        let response = http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
        log-success $"Found issue: ($response.key)"
        
        # Format the output nicely
        {
            key: $response.key
            summary: $response.fields.summary
            status: $response.fields.status.name
            type: $response.fields.issuetype.name
            assignee: ($response.fields.assignee?.displayName? | default "Unassigned")
            reporter: ($response.fields.reporter?.displayName? | default "Unknown")
            priority: ($response.fields.priority?.name? | default "None")
            description: ($response.fields.description? | default "No description")
            created: $response.fields.created
            updated: $response.fields.updated
            epic: ($response.fields.parent?.fields?.summary? | default "None")
            url: $"($config.url)/browse/($response.key)"
        }
    } catch {
        log-error $"Error: Failed to fetch issue ($issue_key)"
        exit 1
    }
}
