---
doc_id: meta/2_python_quickstart/index
chunk_id: meta/2_python_quickstart/index#chunk-15
heading_path: ["Python quickstart", "py: >=3.11,<3.14"]
chunk_type: prose
tokens: 301
summary: "py: >=3.11,<3.14"
---

## py: >=3.11,<3.14

def main():
    return "Hello from Python 3.11 to 3.13"
```

These version specifiers use [PEP 440](https://peps.python.org/pep-0440/) syntax and provide more precise control over Python version requirements than the simple annotations. This is especially useful when you need to ensure compatibility with specific Python features or avoid known issues in certain versions.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/annotate_py_version.mp4"
/>
<br/>

Alternatively, you can set a global version by configuring the INSTANCE_PYTHON_VERSION [environment variable](./meta-47_environment_variables-index.md) to one of the mentioned versions or unset it to use "Latest Stable". If you leave `INSTANCE_PYTHON_VERSION` empty it will inherit "Latest Stable" version, which depends on Windmill.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/set_instance_py_version.mp4"
/>
<br/>

For newly deployed scripts, the annotated or instance version will be assigned to the lockfile, and all future executions will adhere to that specified version. 

For scripts that are already deployed and have no version specified in lockfile, Python 3.11 will be used by default, even if the instance version is changed to a different one.

During test runs or deployments, if there are imported scripts, Windmill will search through all of them to find an annotated version, which will be used as the final version. If no annotated version is found, the instance version will be used instead. 


For [Enterprise Edition](/pricing) (EE) customers, [S3 cache](../../../misc/13_s3_cache/index.mdx) tarballs will be organized and separated by Python version.
