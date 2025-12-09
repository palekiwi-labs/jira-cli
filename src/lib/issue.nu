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
    --type: string = "Story"      # Issue type (Task, Story, Bug, etc.)
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

# Extract description as markdown from an issue
export def get_description [
    issue_key: string
    --output: string     # Save to file (optional)
] {
    let config = get_config
    
    log $"Fetching description for ($issue_key)..."

    # Use Platform API v3 to fetch just the description field
    let url = $"($config.url)/rest/api/3/issue/($issue_key)?fields=description"
    
    try {
        let response = http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
        
        # Extract markdown from ADF structure
        let markdown = $response.fields.description?.content?.0?.content?.0?.text? | default ""
        
        if ($markdown | is-empty) {
            log-error $"No description found for ($issue_key)"
            exit 1
        }
        
        log-success $"Retrieved description for ($issue_key)"
        
        if ($output != null) {
            # Save to file
            $markdown | save --force $output
            log-success $"Description saved to: ($output)"
        } else {
            # Print to stdout
            $markdown
        }
    } catch {
        log-error $"Error: Failed to fetch description for ($issue_key)"
        exit 1
    }
}

# Get available transitions for an issue
export def get_transitions [
    issue_key: string
    --json                # Output as JSON for piping/scripting
] {
    let config = get_config
    
    log $"Fetching available transitions for ($issue_key)..."

    # Use Platform API v3 to get transitions
    let url = $"($config.url)/rest/api/3/issue/($issue_key)/transitions"
    
    try {
        let response = http get --user $config.email --password $config.token --headers [Content-Type application/json] $url
        
        log-success $"Found ($response.transitions | length) available transitions"
        
        # Format the output nicely
        let formatted = $response.transitions | each {|transition|
            {
                id: $transition.id
                name: $transition.name
                to_status: $transition.to.name
                available: $transition.isAvailable
            }
        }
        
        if $json {
            $formatted | to json
        } else {
            $formatted
        }
    } catch {
        log-error $"Error: Failed to fetch transitions for ($issue_key)"
        exit 1
    }
}

# Transition an issue to a new status
export def transition [
    issue_key: string
    transition_name: string   # Name of the transition (e.g., "Start Progress", "Review")
    --comment: string         # Optional comment to add with the transition
    --json                    # Output as JSON for piping/scripting
] {
    let config = get_config
    
    log $"Transitioning ($issue_key) to '($transition_name)'..."

    # First, get available transitions to find the transition ID
    let transitions_url = $"($config.url)/rest/api/3/issue/($issue_key)/transitions"
    
    try {
        let transitions_response = http get --user $config.email --password $config.token --headers [Content-Type application/json] $transitions_url
        
        # Find the transition by name (case-insensitive)
        let transition = $transitions_response.transitions | where {|t| $t.name =~ $transition_name } | first
        
        if ($transition == null) {
            log-error $"Error: Transition '($transition_name)' not found for issue ($issue_key)"
            log-error "Available transitions:"
            $transitions_response.transitions | each {|t| log-error $"  - ($t.name)" }
            exit 1
        }
        
        if not $transition.isAvailable {
            log-error $"Error: Transition '($transition_name)' is not available for issue ($issue_key)"
            exit 1
        }
        
        # Build the transition request
        mut transition_body = {
            transition: {
                id: $transition.id
            }
        }
        
        # Add comment if provided
        if ($comment != null) {
            $transition_body = ($transition_body | merge {
                update: {
                    comment: [{
                        add: {
                            body: {
                                type: "doc"
                                version: 1
                                content: [{
                                    type: "paragraph"
                                    content: [{
                                        type: "text"
                                        text: $comment
                                    }]
                                }]
                            }
                        }
                    }]
                }
            })
        }
        
        # Perform the transition
        let transition_url = $"($config.url)/rest/api/3/issue/($issue_key)/transitions"
        let response = http post --user $config.email --password $config.token --headers [Content-Type application/json] $transition_url ($transition_body | to json)
        
        log-success $"Successfully transitioned ($issue_key) to '($transition.to.name)'"
        
        # Return simple success response
        let result = {
            issue_key: $issue_key
            transition: $transition.name
            new_status: $transition.to.name
            success: true
        }
        
        if $json {
            $result | to json
        } else {
            $result
        }
    } catch {
        log-error $"Error: Failed to transition issue ($issue_key)"
        exit 1
    }
}
