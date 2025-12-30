---
doc_id: ops/extending/custom-applications-go
chunk_id: ops/extending/custom-applications-go#chunk-3
heading_path: ["custom-applications-go"]
chunk_type: code
tokens: 317
summary: "This Go program imports the Dagger SDK and defines two functions."
---
This Go program imports the Dagger SDK and defines two functions. The `build()` function represents the workflow and creates a Dagger client, which provides an interface to the Dagger API. It also defines the build matrix, consisting of two OSs (`darwin` and `linux`) and two architectures (`amd64` and `arm64`), and builds the Go application for each combination. The Go build process is instructed via the `GOOS` and `GOARCH` build variables, which are reset for each case.

Try the Go program by executing the command below from the project directory:

```bash
dagger run go run multibuild/main.go
```

The `dagger run` command executes the specified command in a Dagger session and displays live progress. The Go program builds the application for each OS/architecture combination and writes the build results to the host. You will see the build process run four times, once for each combination. Note that the builds are happening concurrently, because the builds do not depend on eachother.

Use the `tree` command to see the build artifacts on the host, as shown below:

```
tree build
build
├── 1.22
│   ├── darwin
│   │   ├── amd64
│   │   │   └── hello
│   │   └── arm64
│   │       └── hello
│   └── linux
│       ├── amd64
│       │   └── hello
│       └── arm64
│           └── hello
└── 1.23
    ├── darwin
    │   ├── amd64
    │   │   └── hello
    │   └── arm64
    │       └── hello
    └── linux
        ├── amd64
        │   └── hello
        └── arm64
            └── hello
```
