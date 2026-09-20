# Environment patching rules

- Patch only objects that page evidence shows are necessary.
- Patch one minimal causal unit at a time.
- Patch values first. Then patch function stubs. Then patch return-object contracts.
- Run again after each patch. Record whether first divergence moves earlier.