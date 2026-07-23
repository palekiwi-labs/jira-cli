#!/usr/bin/env nu

use lib/api.nu [request]
use lib/config.nu [get_config]
use lib/sprint.nu
use lib/epic.nu
use lib/issue.nu

def main [] {
    print "Usage: jira-cli <sprint|epic|issue> <command> [options]

Subcommands:
  sprint    Sprint operations
  epic      Epic operations
  issue     Issue operations (not yet implemented)"
}

def "main sprint" [] {
    print "Usage: jira-cli sprint <list|active|view|issues|report>

Commands:
  list              List all sprints
  active            Show current active sprint
  view <id>         View sprint details
  issues [id]       List issues in sprint (defaults to active)
  report [id]       Show sprint report (defaults to active)"
}

def "main sprint active" [] {
    sprint get_active
}

def "main sprint view" [sprint_id: int] {
    sprint get_by_id $sprint_id
}

def "main sprint issues" [sprint_id?: int, --status: string] {
    let sprint = if $sprint_id != null {
        sprint get_by_id $sprint_id
    } else {
        sprint get_active
    }
    sprint get_issues $sprint.id --status=$status
}

def "main sprint list" [--state: string = "all"] {
    sprint list --state=$state
}

def "main sprint report" [sprint_id?: int] {
    let sprint = if $sprint_id != null {
        sprint get_by_id $sprint_id
    } else {
        sprint get_active
    }
    sprint get_report $sprint.id
}

def "main epic" [] {
    print "Usage: jira-cli epic <list|view|issues>

Commands:
  list [--done] [--json]     List all epics (optional: filter by done status, output as JSON)
  view <id>                  View epic details
  issues <id>                List issues in an epic"
}

def "main epic list" [
    --done: string     # Filter by completion status (true/false)
    --json             # Output as JSON for piping/scripting
] {
    epic list --done=$done --json=$json
}

def "main epic view" [epic_id: int] {
    epic get_by_id $epic_id
}

def "main epic issues" [epic_id: int] {
    epic get_issues $epic_id
}

def "main issue" [] {
    print "Usage: jira-cli issue <view|create|description|transitions|transition|labels>

Commands:
  view <key> [--json]                      View issue details by key (e.g., PROJ-123)
  create <summary> [options]               Create a new issue
    --project <key>                        Project key (default: SB)
    --type <type>                          Issue type (default: Task)
    --description <text>                   Issue description (direct text)
    --description-file <path>              Read description from markdown file
    --epic <key>                           Link to epic (e.g., SB-9413)
    --labels <labels>                       Labels to add (comma-separated)
    --json                                 Output as JSON
  description <key> [--output <path>]      Extract description as markdown
  transitions <key> [--json]               List available transitions for an issue
  transition <key> <name> [options]        Transition an issue to a new status
    --comment <text>                       Add comment with transition
    --json                                 Output as JSON
  labels <key> [subcommand] [options]     Manage issue labels
    add <labels...>                        Add labels to issue
    remove <labels...>                     Remove labels from issue
    set <labels...>                        Set all labels for issue (replaces existing)
    --json                                 Output as JSON

(Other commands like list, update, assign not yet implemented)"
}

def "main issue view" [
    issue_key: string
    --json                 # Output as JSON for piping/scripting
] {
    issue get_by_key $issue_key --json=$json
}

def "main issue create" [
    summary: string
    --project: string = "SB"       # Project key
    --type: string = "Task"        # Issue type (Task, Story, Bug, etc.)
    --description: string          # Issue description (direct text)
    --description-file: string     # Path to markdown file for description
    --epic: string                 # Epic key to link to
    --labels: string               # Labels to add (comma-separated)
    --json                         # Output as JSON for piping/scripting
] {
    issue create $summary --project=$project --type=$type --description=$description --description-file=$description_file --epic=$epic --labels=$labels --json=$json
}

def "main issue description" [
    issue_key: string
    --output: string              # Save to file
] {
    issue get_description $issue_key --output=$output
}

def "main issue transitions" [
    issue_key: string
    --json                        # Output as JSON for piping/scripting
] {
    issue get_transitions $issue_key --json=$json
}

def "main issue transition" [
    issue_key: string
    transition_name: string       # Name of the transition (e.g., "Start Progress", "Review")
    --comment: string             # Optional comment to add with the transition
    --json                        # Output as JSON for piping/scripting
] {
    issue transition $issue_key $transition_name --comment=$comment --json=$json
}

def "main issue labels" [] {
    print "Usage: jira-cli issue labels <key> <add|remove|set> [options]

Subcommands:
  add <labels...>                        Add labels to issue
  remove <labels...>                     Remove labels from issue  
  set <labels...>                        Set all labels for issue (replaces existing)
    --json                                 Output as JSON

Examples:
  jira-cli issue labels add PROJ-123 bugfix urgent
  jira-cli issue labels remove PROJ-123 old-label duplicate
  jira-cli issue labels set PROJ-123 \"new feature\" backend"
}

def "main issue labels add" [
    issue_key: string
    ...labels: string        # Labels to add (variable number)
    --json                    # Output as JSON for piping/scripting
] {
    issue add_labels $issue_key $labels --json=$json
}

def "main issue labels remove" [
    issue_key: string
    ...labels: string        # Labels to remove (variable number)
    --json                    # Output as JSON for piping/scripting
] {
    issue remove_labels $issue_key $labels --json=$json
}

def "main issue labels set" [
    issue_key: string
    ...labels: string        # Labels to set (replaces all existing)
    --json                    # Output as JSON for piping/scripting
] {
    issue set_labels $issue_key $labels --json=$json
}
