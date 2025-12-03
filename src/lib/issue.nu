use config.nu [get_config]
use logger.nu [log log-success log-error]

# Get a specific issue by key (e.g., "PROJ-123")
export def get_by_key [
    issue_key: string
    --json                # Output as JSON for piping/scripting
] {
    let config = get_config
    
    log $"Fetching issue ($issue_key)..."

    # Use Platform API v3 for issue details
    let url = $"($config.url)/rest/api/3/issue/($issue_key)"
    
    try {
        let response = http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
        log-success $"Found issue: ($response.key)"
        
        # Format the output nicely
        let formatted = {
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
        
        if $json {
            $formatted | to json
        } else {
            $formatted
        }
    } catch {
        log-error $"Error: Failed to fetch issue ($issue_key)"
        exit 1
    }
}

# Create a new issue
export def create [
    summary: string              # Issue summary/title
    --project: string = "SB"     # Project key
    --type: string = "Task"      # Issue type (Task, Story, Bug, etc.)
    --description: string        # Issue description (direct text)
    --description-file: string   # Path to markdown file for description
    --epic: string               # Epic key to link to (e.g., "SB-9413")
    --json                       # Output as JSON for piping/scripting
] {
    let config = get_config
    
    log $"Creating issue: ($summary)..."

    # Use Platform API v3 for issue creation
    let url = $"($config.url)/rest/api/3/issue"
    
    # Build the fields object
    mut fields = {
        project: { key: $project }
        issuetype: { name: $type }
        summary: $summary
    }
    
    # Determine description source (file or direct text)
    let desc_text = if ($description_file != null) {
        # Validate both are not provided
        if ($description != null) {
            log-error "Error: Cannot use both --description and --description-file"
            exit 1
        }
        # Check if file exists
        if not ($description_file | path exists) {
            log-error $"Error: File not found: ($description_file)"
            exit 1
        }
        # Read markdown file content
        open $description_file | str trim
    } else if ($description != null) {
        $description
    } else {
        null
    }
    
    # Add description if provided (markdown preserved as plain text in ADF)
    if ($desc_text != null) {
        $fields = ($fields | merge {
            description: {
                type: "doc"
                version: 1
                content: [{
                    type: "paragraph"
                    content: [{
                        type: "text"
                        text: $desc_text
                    }]
                }]
            }
        })
    }
    
    # Add epic parent if provided
    if ($epic != null) {
        $fields = ($fields | merge { parent: { key: $epic } })
    }
    
    let body = { fields: $fields }
    
    try {
        let response = http post --user $config.email --password $config.token --headers [Content-Type application/json] $url ($body | to json)
        
        log-success $"Created issue: ($response.key)"
        
        let formatted = {
            key: $response.key
            id: $response.id
            url: $"($config.url)/browse/($response.key)"
        }
        
        if $json {
            $formatted | to json
        } else {
            $formatted
        }
    } catch {
        log-error "Error: Failed to create issue"
        log-error $"Make sure the project '($project)' exists and issue type '($type)' is valid"
        if ($epic != null) {
            log-error $"Also check that epic '($epic)' exists"
        }
        exit 1
    }
}
