use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct Mem0Input {
    pub action: String,
    pub text: Option<String>,
    pub query: Option<String>,
    pub memory_ids: Option<Vec<String>>,
}

#[derive(Serialize)]
pub struct Mem0Output {
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
}

pub fn main(input: Mem0Input) -> anyhow::Result<Mem0Output> {
    // Simulate mem0 integration
    match input.action.as_str() {
        "add" => {
            if let Some(text) = &input.text {
                eprintln!("[mem0] Adding memory: {}", text);
                Ok(Mem0Output {
                    success: true,
                    message: "Memory added successfully".to_string(),
                    data: Some(serde_json::json!({
                        "memory_id": "mem0_12345",
                        "text": text
                    })),
                })
            } else {
                Ok(Mem0Output {
                    success: false,
                    message: "Text required for add action".to_string(),
                    data: None,
                })
            }
        },
        "search" => {
            if let Some(query) = &input.query {
                eprintln!("[mem0] Searching memory: {}", query);
                Ok(Mem0Output {
                    success: true,
                    message: "Search completed".to_string(),
                    data: Some(serde_json::json!({
                        "results": [
                            {
                                "id": "mem0_12345",
                                "memory": query,
                                "score": 0.95
                            }
                        ]
                    })),
                })
            } else {
                Ok(Mem0Output {
                    success: false,
                    message: "Query required for search action".to_string(),
                    data: None,
                })
            }
        },
        _ => {
            Ok(Mem0Output {
                success: false,
                message: format!("Unknown action: {}", input.action),
                data: None,
            })
        }
    }
}