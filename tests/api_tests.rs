use jira_cli::api::SprintIssuesResponse;
use std::fs;

#[test]
fn test_deserialize_sprint_issues_with_additional_fields() {
    let json_data = fs::read_to_string("tests/fixtures/sprint_issues.json")
        .expect("Failed to read test fixture");
    
    let response: SprintIssuesResponse = serde_json::from_str(&json_data)
        .expect("Failed to deserialize sprint issues");
    
    assert_eq!(response.total, 3);
    assert_eq!(response.issues.len(), 3);
    
    // Test first issue - has epic and custom fields
    let first_issue = &response.issues[0];
    assert_eq!(first_issue.key, "PROJ-123");
    assert_eq!(first_issue.fields.summary, Some("Implement user login functionality".to_string()));
    
    // Test explicitly typed fields
    assert_eq!(first_issue.fields.labels, Some(vec!["authentication".to_string(), "security".to_string()]));
    assert_eq!(first_issue.fields.created, Some("2024-01-15T10:00:00.000+0000".to_string()));
    assert!(first_issue.fields.epic.is_some());
    
    let epic = first_issue.fields.epic.as_ref().unwrap();
    assert_eq!(epic.name, Some("User Authentication Epic".to_string()));
    assert_eq!(epic.done, Some(false));
    
    // Test additional_fields HashMap contains custom fields
    assert!(first_issue.fields.additional_fields.contains_key("customfield_10016"));
    assert_eq!(first_issue.fields.additional_fields.get("customfield_10016").unwrap().as_i64(), Some(8));
    assert_eq!(
        first_issue.fields.additional_fields.get("customfield_10020").unwrap().as_str(),
        Some("sprint-1")
    );
    
    // Test third issue - has parent
    let third_issue = &response.issues[2];
    assert!(third_issue.fields.parent.is_some());
    
    let parent = third_issue.fields.parent.as_ref().unwrap();
    assert_eq!(parent.key, "PROJ-123");
    assert_eq!(parent.fields.as_ref().unwrap().summary, Some("Implement user login functionality".to_string()));
}

#[test]
fn test_deserialize_empty_sprint_issues() {
    let json_data = fs::read_to_string("tests/fixtures/empty_sprint_issues.json")
        .expect("Failed to read test fixture");
    
    let response: SprintIssuesResponse = serde_json::from_str(&json_data)
        .expect("Failed to deserialize empty sprint issues");
    
    assert_eq!(response.total, 0);
    assert_eq!(response.issues.len(), 0);
}
