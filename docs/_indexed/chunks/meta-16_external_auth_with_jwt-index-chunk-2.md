---
doc_id: meta/16_external_auth_with_jwt/index
chunk_id: meta/16_external_auth_with_jwt/index#chunk-2
heading_path: ["External auth with JWT", "Embed public apps using your own authentification"]
chunk_type: prose
tokens: 131
summary: "Embed public apps using your own authentification"
---

## Embed public apps using your own authentification

On the Enterprise Edition, it is possible for one to embed public apps and reuse the embedding app auth and userbase. To do so, use an iframe as usual with the public app url as `src`. 

For instance: `https://your_instance.com/public/foo/a7f83d827f8bbb3a332c730659f4cf39`, but in addition, append to the url the jwt token, separated by a '/'.

`https://your_instance.com/public/foo/a7f83d827f8bbb3a332c730659f4cf39/eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IiJ9.ey1c2VybmFtZSI6ImZvbyIsImVtYWlsIjoiZm9vQHdpbmRtaWxsLmRldiIsImlzX2FkbWluIjp0cnVlLCJpc19vcGVyYXRvciI6ZmFsc2UsImZvbGRlcnMiOltdLCJncm91cHMiOltdLCJ3b3Jrc3BhY2VfaWQiOiJmb28iLCJpYXQiOjE3MjM0OTc0ODksImV4cCI6MTcyMzUwMTA4OX0.nnhAGjR_PbuHhLzVCDrTZmRRU9zQd_gpona8bSuvIWlK6Taaxgojn-8tQk1IDykw_WHdnLPgWrOt9uGPAPFD0SsLqK_P-aM1Q8KU-X-Ve3qMQ-Sru5IpE-BgCnb5n0_s2mR6-Ebl6exPYQWJFFNWQ_cj6lDF2fYS71hv2IeQqwssHU4YD1ujUl0rm1rCzRKGuK-iVr9mdFywB2K95iBnhJ0-XLnysjyM4UtutGqLqVZgIHabm2HhgFNNLfHtpfgNYtrk3l3lxCYsr9jmD5Z3lnLcWNhBDWxBlneyIp7yt73hLt7v5QKVoKzFgU_Ikf_FVx0TC7dmUvEKNhqfjfKNA`

This will make the app act such that the user authentified is the one that corresponds to the jwt payload. Windmill uses just-in-time provisioning by default and the user doesn't need to have been pre-provisioned for it to works.
