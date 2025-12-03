#!/usr/bin/env nu

use lib/api.nu [request]
use lib/config.nu [get_config]
use lib/sprint.nu
use lib/epic.nu

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
  list [--done]     List all epics (optional: filter by done status)
  view <id>         View epic details
  issues <id>       List issues in an epic"
}

def "main epic list" [--done: string] {
    epic list --done=$done
}

def "main epic view" [epic_id: int] {
    epic get_by_id $epic_id
}

def "main epic issues" [epic_id: int] {
    epic get_issues $epic_id
}

def "main issue" [] {
    print "Usage: jira-cli issue <view|list|create|update|assign|transition>
(Not yet implemented - coming in Phase 3)"
}
