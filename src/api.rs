use anyhow::{Result, bail};
use reqwest::Client;
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::collections::HashMap;

use crate::config::Config;

pub struct Api {
    client: Client,
    email: String,
    token: String,
    base_url: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct BoardSprints {
    #[serde(rename = "isLast")]
    pub is_last: bool,
    #[serde(rename = "maxResults")]
    pub max_results: u32,
    #[serde(rename = "startAt")]
    pub start_at: u32,
    pub total: u32,
    pub values: Vec<Sprint>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Sprint {
    pub id: u32,
    #[serde(rename = "self")]
    pub self_link: String,
    pub state: SprintState,
    pub name: String,
    #[serde(rename = "startDate")]
    pub start_date: Option<String>,
    #[serde(rename = "endDate")]
    pub end_date: Option<String>,
    #[serde(rename = "completeDate")]
    pub complete_date: Option<String>,
    #[serde(rename = "originBoardId")]
    pub origin_board_id: Option<u32>,
    pub goal: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum SprintState {
    Future,
    Active,
    Closed,
}

#[derive(Serialize)]
pub struct SprintParams {
    state: Option<String>,
    #[serde(rename = "maxResults")]
    max_results: Option<u32>,
    #[serde(rename = "startAt")]
    start_at: Option<u32>,
}

impl SprintParams {
    pub fn new(state: Option<String>, max_results: Option<u32>, start_at: Option<u32>) -> Self {
        SprintParams {
            state,
            max_results,
            start_at,
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SprintIssuesResponse {
    pub expand: Option<String>,
    pub issues: Vec<Issue>,
    #[serde(rename = "maxResults")]
    pub max_results: u32,
    #[serde(rename = "startAt")]
    pub start_at: u32,
    pub total: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Issue {
    pub id: String,
    pub key: String,
    #[serde(rename = "self")]
    pub self_link: String,
    pub fields: IssueFields,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IssueFields {
    pub assignee: Option<Assignee>,
    pub created: Option<String>,
    pub description: Option<serde_json::Value>,
    pub epic: Option<Epic>,
    pub issuetype: Option<IssueType>,
    pub labels: Option<Vec<String>>,
    pub parent: Option<IssueReference>,
    pub priority: Option<Priority>,
    pub project: Option<Project>,
    pub reporter: Option<Assignee>,  // Uses same structure as assignee
    pub status: Option<IssueStatus>,
    pub subtasks: Option<Vec<SubTask>>,
    pub summary: Option<String>,
    pub updated: Option<String>,
    
    // Catch-all for any additional fields (custom fields, etc.)
    #[serde(flatten)]
    pub additional_fields: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IssueStatus {
    pub name: Option<String>,
    pub id: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IssueType {
    pub name: Option<String>,
    pub id: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Assignee {
    #[serde(rename = "displayName")]
    pub display_name: Option<String>,
    #[serde(rename = "emailAddress")]
    pub email_address: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Priority {
    pub name: Option<String>,
    pub id: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Project {
    pub key: Option<String>,
    pub name: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IssueReference {
    pub id: String,
    pub key: String,
    #[serde(rename = "self")]
    pub self_link: String,
    pub fields: Option<IssueReferenceFields>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct IssueReferenceFields {
    pub summary: Option<String>,
    pub status: Option<IssueStatus>,
    pub issuetype: Option<IssueType>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Epic {
    pub id: u32,
    #[serde(rename = "self")]
    pub self_link: String,
    pub name: Option<String>,
    pub summary: Option<String>,
    pub color: Option<EpicColor>,
    pub done: Option<bool>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct EpicColor {
    pub key: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct SubTask {
    pub id: String,
    pub key: String,
    #[serde(rename = "self")]
    pub self_link: String,
    pub fields: Option<IssueReferenceFields>,
}

#[derive(Serialize)]
pub struct SprintIssuesParams {
    #[serde(rename = "startAt")]
    start_at: Option<u32>,
    #[serde(rename = "maxResults")]
    max_results: Option<u32>,
    jql: Option<String>,
    #[serde(rename = "validateQuery")]
    validate_query: Option<bool>,
    fields: Option<String>,
    expand: Option<String>,
}

impl SprintIssuesParams {
    pub fn new(
        start_at: Option<u32>,
        max_results: Option<u32>,
        jql: Option<String>,
        validate_query: Option<bool>,
        fields: Option<String>,
        expand: Option<String>,
    ) -> Self {
        SprintIssuesParams {
            start_at,
            max_results,
            jql,
            validate_query,
            fields,
            expand,
        }
    }
}

impl Api {
    pub fn from_config(config: Config) -> Api {
        Api {
            client: Client::new(),
            email: config.email,
            token: config.token,
            base_url: config.url,
        }
    }

    async fn handle_response<T: DeserializeOwned>(&self, response: reqwest::Response) -> Result<T> {
        let status = response.status();
        let response_text = response.text().await?;

        if !status.is_success() {
            bail!( "API request failed with status: {}", status)
        } else {
            serde_json::from_str(&response_text).map_err(|e| {
                anyhow::anyhow!("Failed to parse JSON response: {}", e)
            })
        }
    }

    pub async fn get_board_sprints(&self, board_id: u32, params: SprintParams) -> Result<BoardSprints> {
        let url = format!("{}/rest/agile/1.0/board/{}/sprint", self.base_url, board_id);

        let response = self
            .client
            .get(&url)
            .query(&params)
            .header("Accept", "application/json")
            .basic_auth(&self.email, Some(&self.token))
            .send()
            .await?;

        self.handle_response(response).await
    }

    pub async fn get_sprint_by_id(&self, sprint_id: u32) -> Result<Sprint> {
        let url = format!("{}/rest/agile/1.0/sprint/{}", self.base_url, sprint_id);

        let response = self
            .client
            .get(&url)
            .header("Accept", "application/json")
            .basic_auth(&self.email, Some(&self.token))
            .send()
            .await?;

        self.handle_response(response).await
    }

    pub async fn get_sprint_issues(
        &self,
        board_id: u32,
        sprint_id: u32,
        params: SprintIssuesParams,
    ) -> Result<SprintIssuesResponse> {
        let url = format!(
            "{}/rest/agile/1.0/board/{}/sprint/{}/issue",
            self.base_url, board_id, sprint_id
        );

        let response = self
            .client
            .get(&url)
            .query(&params)
            .header("Accept", "application/json")
            .basic_auth(&self.email, Some(&self.token))
            .send()
            .await?;

        self.handle_response(response).await
    }
}
