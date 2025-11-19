use logger.nu [log-error]

export def request-agile [config: record, endpoint: string] {
    request "agile" $config $endpoint
}

export def request-platform [config: record, endpoint: string] {
    request "agile" $config $endpoint
}

export def request [
    api_version: string
    config: record
    endpoint: string
] {
    let base_path = match $api_version {
        "agile" => "/rest/agile/1.0",
        "platform" => "/rest/api/3"
        _ => {
            error make {
                msg: $"Invalid API version: '($api_version)'"
                label: {
                    text: "must be 'agile' or 'platform'",
                    span: (metadata $api_version).span
                }
            }
        }
    }

    let url = $"($config.url)($base_path)($endpoint)"

    let response = (
        http get
            --full
            --allow-errors
            --user $config.email
            --password $config.token
            --headers [Content-Type application/json]
            $url
    )

    match $response.status {
        200 => { $response.body }
        _ => { 
            log-error $"($response.body.errorMessages | to text)"
            exit 1
        }
    }
}
