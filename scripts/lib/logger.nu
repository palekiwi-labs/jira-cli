export def log [message: string] {
    if not ($env.JIRA_QUIET? | default false) {
        print -e $"(ansi default)($message)(ansi reset)"
    }
}

export def log-success [message: string] {
    if not ($env.JIRA_QUIET? | default false) {
        print -e $"(ansi green)($message)(ansi reset)"
    }
}

export def log-error [message: string] {
    print --stderr $"(ansi red)($message)(ansi reset)"
}
