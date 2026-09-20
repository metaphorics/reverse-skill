# Source Code Audit Checklist (Condensed)

- [ ] List every external input entry point.
- [ ] Check authentication and authorization middleware coverage.
- [ ] Bind every multi-tenant ID to the session.
- [ ] Check deserialization, pickle, and YAML load.
- [ ] Check SSRF outbound access and protocol limits.
- [ ] Check key and token storage.
- [ ] Check file-upload paths and types.
- [ ] Check dangerous exec, system, and Runtime calls.
