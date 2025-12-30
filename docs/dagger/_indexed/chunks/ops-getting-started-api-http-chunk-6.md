---
doc_id: ops/getting-started/api-http
chunk_id: ops/getting-started/api-http#chunk-6
heading_path: ["api-http", "export binary from container to host filesystem"]
chunk_type: mixed
tokens: 96
summary: "build=$(dagger query <<EOF | jq -r ."
---
build=$(dagger query <<EOF | jq -r .container.from.withDirectory.withWorkdir.withExec.file.export
{
  container {
    from(address:"golang:latest") {
      withDirectory(path:"/src", directory:"$source") {
        withWorkdir(path:"/src/hello") {
          withExec(args:["go", "build", "-o", "dagger-builds-hello", "."]) {
            file(path:"./dagger-builds-hello") {
              export(path:"./dagger-builds-hello")
            }
          }
        }
      }
    }
  }
}
EOF
)

if [ -n "$build" ]; then
	echo "Build successful"
else
	echo "Build unsuccessful"
fi
```

Run it:
```bash
chmod +x ./build.sh
./build.sh
```

On completion, the built Go application will be available in the working directory on the host.
