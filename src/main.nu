#!/usr/bin/env nu

use lib/api.nu [request]
use lib/config.nu [get_config]
use lib/sprint.nu

def main [] {
    print "Usage: jira-cli <sprint|issue> <command> [options]

Subcommands:
  sprint    Sprint operations
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

def "main sprint active" [--quiet(-q)] {
    if $quiet {
        $env.JIRA_QUIET = true
    }
    get_current_sprint
}

def "main sprint view" [sprint_id: int, --quiet(-q)] {
    if $quiet {
        $env.JIRA_QUIET = true
    }
    get_sprint_by_id $sprint_id
}

def "main sprint issues" [
    sprint_id?: int
    --status: string
    --quiet(-q)
] {
    if $quiet {
        $env.JIRA_QUIET = true
    }
    let sprint = if $sprint_id != null {
        get_sprint_by_id $sprint_id
    } else {
        get_current_sprint
    }
    get_sprint_issues $sprint.id --status=$status
}

def "main sprint list" [--state: string = "all"] {
    list_sprints --state=$state
}

def "main sprint report" [sprint_id?: int, --quiet(-q)] {
    if $quiet {
        $env.JIRA_QUIET = true
    }
    let sprint = if $sprint_id != null {
        get_sprint_by_id $sprint_id
    } else {
        get_current_sprint
    }
    get_sprint_report $sprint.id
}

def "main issue" [] {
    print "Usage: jira-cli issue <view|list|create|update|assign|transition>
(Not yet implemented - coming in Phase 3)"
}
