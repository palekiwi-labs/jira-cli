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
    print "Usage: jira-cli issue <view|create>

Commands:
  view <key> [--json]                      View issue details by key (e.g., PROJ-123)
  create <summary> [options]               Create a new issue
    --project <key>                        Project key (default: SB)
    --type <type>                          Issue type (default: Task)
    --description <text>                   Issue description
    --epic <key>                           Link to epic (e.g., SB-9413)
    --json                                 Output as JSON

(Other commands like list, update, assign, transition not yet implemented)"
}

def "main issue view" [
    issue_key: string
    --json                 # Output as JSON for piping/scripting
] {
    issue get_by_key $issue_key --json=$json
}

def "main issue create" [
    summary: string
    --project: string = "SB"    # Project key
    --type: string = "Task"     # Issue type (Task, Story, Bug, etc.)
    --description: string       # Issue description
    --epic: string              # Epic key to link to
    --json                      # Output as JSON for piping/scripting
] {
    issue create $summary --project=$project --type=$type --description=$description --epic=$epic --json=$json
}
