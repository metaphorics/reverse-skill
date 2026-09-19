# reverse-skill Quick Start and Community Issue Guide

## Project scope

`reverse-skill` is a collection of reverse-engineering and security-research skills, rules, and tool documentation for AI clients. It is not a standalone executable application. Before use, confirm that you have clear authorization for the target, or that you work in a legal CTF, teaching, or test environment.

## Basic use

Download the repository first:

    git clone https://github.com/zhaoxuya520/reverse-skill.git
    cd reverse-skill

Give the repository directory to your AI client as its workspace or document source. Core documents include:

- `RULES.md`: general rules and security boundaries.
- `skills/MASTER-ROUTING.md`: skill routing and task separation.
- `skills/*/SKILL.md`: skill descriptions for each specialist area.
- `docs/platforms/`: tool installation notes for each operating system.

This project remains client-neutral. Follow each client's official documentation for loading rules, plugins, and synchronization. Do not assume that a plugin or sync format for one client also works for another client.

The most reliable general method is to open the complete repository root as the workspace. Do not copy only the `skills/` directory into the client. Confirm that the client can read `AGENTS.md` and `RULES.md` from the root. Then run the platform-native `master-route`. If the client does not load project rules automatically, cite `RULES.md` and the target `SKILL.md` in the conversation.

## OpenCode, Codex, and synchronization issues

If the client shows `Not Synchronizable` or cannot synchronize, check these items first:

- The workspace points to the complete repository root.
- File permissions allow the client to read the workspace.
- The client supports this directory format.

The most reliable alternative is to open the repository in the local workspace. Cite the required rules or skill documents in the conversation. If the problem persists, include the client version, operating system, complete error message, and minimal reproduction steps in the report.

## When an AI refuses an analysis request

An AI safety policy may still refuse an operation after a prompt says, "I have authorization." Process only targets that you are authorized to assess. Do not request unauthorized access, credential theft, persistence, or destructive actions. You can limit the request to code comprehension, sample analysis, vulnerability remediation, CTF work, or defensive validation. For a specific APK, website, or account, prepare a verifiable authorization scope and test environment first.

## Python tools and uv

Use this command for an isolated command-line tool:

    uv tool install PACKAGE_NAME

Use an isolated environment for project dependencies:

    uv venv
    uv pip install -r requirements.txt

Do not replace every `pip` string with `uv pip`. `python -m pip`, `pipx` bootstrap, and an existing virtual environment have different uses. If `uv` is not installed, use the operating-system package manager or create an explicit virtual environment. Do not install security tools into the system-wide Python environment.

Read [Installation and Download Security Guidance](UV-AND-DOWNLOAD-SECURITY.md) for more detail about installation and archive handling.

## Archive warnings and download security

Reverse-engineering tools may contain binaries, debuggers, packed files, or test data. These contents can trigger antivirus heuristics. An antivirus warning does not prove that an archive is safe or malicious. Do not disable antivirus protection or blindly bypass a warning.

Before opening an archive, download it from the intended HTTPS repository or release page. Compare its checksum or release digest when one is available. Inspect the archive contents. Scan the archive with current security software. Do not execute an unknown binary, script, or installer merely because the archive downloaded successfully.

## Accounts, contributions, and incomplete reports

Follow the terms of service for the AI client, GitHub, tool vendors, and target environment. The repository cannot prevent third-party platforms from restricting an account. It cannot decide account policy for those platforms. To contribute radare2 or another skill, read `skills/CONTRIBUTING.md`. Submit a small pull request that you can verify.

Only reports with the complete error message, environment information, and reproduction steps can support further repair. A report that contains only "virus", "gaha", or "test" is not actionable. Add the file name, download URL, scanning product, version, and reproduction method.

## External models and APIs

This repository does not bundle, proxy, or resell the Grok/xAI API. It does not collect or distribute Grok API keys. Users configure models and API endpoints in the selected AI client or provider. When you use a third-party relay service, verify the provider, data-processing terms, and key risks yourself.
