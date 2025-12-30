---
doc_id: meta/31_workflows_as_code/index
chunk_id: meta/31_workflows_as_code/index#chunk-2
heading_path: ["Workflows as code", "You can specify tag to run the task on a specific type of worker, e.g. @task(tag=\"custom_tag\")"]
chunk_type: code
tokens: 215
summary: "You can specify tag to run the task on a specific type of worker, e.g. @task(tag=\"custom_tag\")"
---

## You can specify tag to run the task on a specific type of worker, e.g. @task(tag="custom_tag")
def heavy_compute(n: int):
    df = pd.DataFrame(np.random.randn(100, 4), columns=list('ABCD'))
    return df.sum().sum()


@task
def send_result(res: int, email: str):
    # logs of the subtask are available in the main task logs
    print(f"Sending result {res} to {email}")
    return "OK"

def main(n: int):
    l = []

    # to run things in parallel, simply use multiprocessing Pool map instead: https://docs.python.org/3/library/multiprocessing.html
    for i in range(n):
        l.append(heavy_compute(i))
    print(l)
    return send_result(sum(l), "example@example.com")

```

> **Note**: When using multiprocessing or multithreading with the Windmill client, create a separate client instance per thread/process using `wmill.Windmill()` as the client is not thread-safe.

</TabItem>
<TabItem value="deno" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
import { task } from 'windmill-client';

export async function hello(name: string) {
	return 'Hello:' + name;
}

export async function main() {
	//It's the function itself that needs to be wrapped with task, and it's always a promise even
	await task(hello)('BAR');
	return await task(hello)('FOO');
}
```

</TabItem>
</Tabs>
