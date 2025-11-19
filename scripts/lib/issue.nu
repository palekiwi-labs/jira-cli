use api.nu [request-platform]

export def view [issue_key: string] {
    let config = get_config

    request-platform $config $"/issue/($issue_key)?fields=issuelinks&expand=names,schema,operations,changelog,versionedRepresentations,editmeta,devStatus"
    # | get fields
    # | transpose key value
    # | sort-by key
    # | transpose -r -d
    | to json
}
