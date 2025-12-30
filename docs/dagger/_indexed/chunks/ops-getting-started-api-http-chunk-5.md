---
doc_id: ops/getting-started/api-http
chunk_id: ops/getting-started/api-http#chunk-5
heading_path: ["api-http", "get Go examples source code repository"]
chunk_type: prose
tokens: 27
summary: "source=$(dagger query <<EOF | jq -r ."
---
source=$(dagger query <<EOF | jq -r .git.branch.tree.id
{
  git(url:"https://go.googlesource.com/example") {
    branch(name:"master") {
      tree {
        id
      }
    }
  }
}
EOF
)
