use async_trait::async_trait;
use anyhow::Result;
use serde_json::Value;

#[async_trait]
pub trait HttpClient: Send + Sync {
    async fn get(&self, url: &str, headers: Vec<(&str, &str)>) -> Result<Value>;
}

pub struct Client {
    client: reqwest::Client,
}

impl Client {
    pub fn new() -> Result<Self> {
        let client = reqwest::Client::builder()
            .user_agent("jira-cli/0.1.0")
            .build()?;
        Ok(Self { client })
    }
}

#[async_trait]
impl HttpClient for Client {
    async fn get(&self, url: &str, headers: Vec<(&str, &str)>) -> Result<Value> {
        let mut request = self.client.get(url);

        for (key, value) in headers {
            request = request.header(key, value);
        }

        let response = request.send().await?;
        let json: Value = response.json().await?;

        Ok(json)
    }
}

// Mock implementation for testing
#[cfg(test)]
pub struct MockClient {
    responses: std::collections::HashMap<String, Value>,
}

#[cfg(test)]
impl MockClient {
    pub fn new() -> Self {
        Self {
            responses: std::collections::HashMap::new(),
        }
    }

    pub fn add_response(&mut self, url: &str, response: Value) {
        self.responses.insert(url.to_string(), response);
    }
}

#[cfg(test)]
#[async_trait]
impl HttpClient for MockClient {
    async fn get(&self, url: &str, _headers: Vec<(&str, &str)>) -> Result<Value> {
        if let Some(response) = self.responses.get(url) {
            Ok(response.clone())
        } else {
            Err(anyhow::anyhow!("No mock response for URL: {}", url))
        }
    }
}
