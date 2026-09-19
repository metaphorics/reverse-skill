# OWASP LLM and Agentic AI Top 10 (2025-2026)

## OWASP Top 10 for LLM Applications v2.0 (2025)

| # | Risk | Core issue | Test focus |
|---|------|---------|---------|
| LLM01 | Prompt Injection | Crafted input controls model behavior | Direct injection, indirect injection, encoding bypass |
| LLM02 | Sensitive Information Disclosure | PII, API keys, or training data leak | Prompt extraction, output analysis |
| LLM03 | Supply Chain | Poisoned models, libraries, or datasets | Model origin verification, dependency scanning |
| LLM04 | Data and Model Poisoning | Backdoors in training or fine-tuning data | Data provenance, abnormal behavior detection |
| LLM05 | Improper Output Handling | Output causes XSS, SQLi, or RCE | Downstream system injection tests |
| LLM06 | Excessive Agency | Excessive tool access or autonomy causes harm | Permission audit, human-in-the-loop tests |
| LLM07 | System Prompt Leakage | Hidden instructions, keys, or business logic are extracted | Cascading extraction, canary token |
| LLM08 | Vector and Embedding Weaknesses | RAG pipeline attack or embedding inversion | Retrieval poisoning, semantic similarity attack |
| LLM09 | Misinformation | Hallucinations create security risk in high-risk scenarios | Factuality checks, confidence calibration |
| LLM10 | Unbounded Consumption | DoS or Denial-of-Wallet | Token consumption tests, rate limits |

## OWASP Top 10 for Agentic Applications (ASI 2026)

| # | Risk | Core harm | Test focus |
|---|------|---------|---------|
| ASI01 | Agent Goal Hijack | Malicious input or tool output hijacks the goal | Instruction override, goal tampering |
| ASI02 | Tool Misuse and Exploitation | Legitimate tools are used in unexpected ways | Tool-chain composition, parameter injection |
| ASI03 | Identity and Privilege Abuse | The agent performs broken-access-control operations | Credential theft, delegation-chain tests |
| ASI04 | Agentic Supply Chain | MCP descriptors or third-party tools create live risk | Dynamic supply-chain scanning |
| ASI05 | Unexpected Code Execution | Prompt to tool to script RCE chain | Multi-layer code execution tests |
| ASI06 | Memory and Context Poisoning | Long-term memory or embeddings are poisoned | Memory persistence attacks |
| ASI07 | Insecure Inter-Agent Communication | Communication between agents is tampered with | Man-in-the-middle, request replay |
| ASI08 | Cascading Failures | One failure triggers a system-wide collapse | Failure propagation tests |
| ASI09 | Human-Agent Trust Exploitation | Human operators approve dangerous actions after manipulation | Authority-bias and urgency tests |
| ASI10 | Rogue Agents | Agent self-replication or persistent malicious behavior | Persistence backdoor detection |

## Actual Data Distribution

The observed issue distribution in real assessments:
- LLM01 Prompt Injection: ~45%
- LLM06 Sensitive Information Disclosure: ~20%
- LLM08 Excessive Agency: ~15%
- The remaining 7 items: ~20%

## Key Defense Principles

1. Separate planning from execution. The model that explains intent must differ from the model that executes actions.
2. Bind identity, purpose, scope, and time limit. Do not use broad environment permissions.
3. Record everything. Treat tool calls, memory, and communication as first-class security telemetry.
4. Control the blast radius. Prioritize circuit breakers, rollback, and emergency stop over convenience.
5. Treat all natural-language input, including retrieved content, as untrusted.
6. Treat output as untrusted too. Sanitize it before rendering, execution, or queries.
