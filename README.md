# MI-RETRIEVE-CODE

**MI-RETRIEVE-CODE** is a project to help people save, organize, retrieve, and share useful information using unique reference codes.

## Project goal

Build one easy-to-use platform with an integrated MI Assistant. The long-term plan is a complete AI ecosystem with user and administrator controls.

## Separate personal memory tool: MI MEMORY

**MI MEMORY** is a separate personal memory and integration tool in its own `mi-memory/` folder. Its full name is **Universal Personal AI Memory System**.

- Main project: stores and manages the user's projects and memory.
- MI MEMORY: preserves and retrieves user-authorized memory and provides an integration layer for compatible AI clients, including MCP-based connections.
- Both remain part of the same ecosystem, but MI MEMORY is designed so it can later be deployed or maintained independently.

Read the [MI MEMORY specification](mi-memory/README.md) and [MI CONNECT MCP component notes](mi-connect/README.md).

**Status:** A local stdio MCP prototype for MI MEMORY's integration layer is available in `mi-connect/`. It exposes a non-sensitive status tool and a retrieval placeholder that intentionally returns no private data. A standalone fail-closed read-policy helper and 11 Node tests now cover the future MI ACCOUNT LINK permission checks, but the helper is not wired to authentication or retrieval. The MI account API, production authentication, server-side audit logs, remote deployment, and AI-client connection are not implemented. It is not connected to ChatGPT or any other AI platform.

## Current prototype

- Save a title and text in the current browser.
- Generate a unique reference code.
- Retrieve saved text in the same browser.

**Important:** The current prototype uses browser local storage. Codes do not yet retrieve information across different devices or users. Do not store passwords, private documents, or sensitive information in this prototype.

## Command directory

These are planned command names. A command is not considered active until its feature is implemented and tested.

| Command | Planned purpose |
| --- | --- |
| `/create-project` | Start a new project |
| `/save-project` | Save content |
| `/retrieve-project` | Retrieve content by code |
| `/update-project` | Update saved content |
| `/share-project` | Share content with permitted people |
| `/revoke-access` | Revoke future access |
| `/search-project` | Search saved content |
| `/summarize` | Summarize supplied content |
| `/translate` | Translate supplied content |
| `/research` | Organize research |
| `/write` | Draft written content |
| `/create-code` | Generate a reference code |
| `/analyze-file` | Analyze an uploaded file |
| `/generate-report` | Prepare a report |

## Development roadmap

1. Improve the single-page website and make it mobile-friendly.
2. Add a secure cloud database so users can retrieve content across devices.
3. Add accounts, ownership, permissions, and access controls.
4. Add sharing options, expiry settings, and access revocation.
5. Build the MI Assistant command interface.
6. Complete the MI CONNECT MCP component for MI MEMORY and connect it to the MI account and project API.
7. Add AI-powered tools only when an appropriate service and safe configuration are available.
8. Test the platform, privacy controls, backups, and accessibility.

## Universal AI Memory (core planned feature)

MI-RETRIEVE-CODE is intended to become a user-controlled, portable memory hub for work done across supported AI services and accounts. The goal is to let the owner retrieve an authorized project context with an MI code and continue work in a new ChatGPT account or another supported AI assistant.

### What this feature should do

- Store project notes, decisions, requirements, files, summaries, and progress in one owner-controlled workspace.
- Support securely linking two or more of the owner's own AI accounts, with separate authorization, account-level controls, and selective sharing between linked accounts.
- Create a portable project memory/context package that an AI assistant can read when the owner explicitly provides it or authorizes a supported connection.
- Support importing conversation exports or user-selected content from AI services that provide an export or supported integration.
- Let the owner select which projects or memory sections to share with an AI, for how long, and with which permissions.
- Keep project history and versions so the assistant can understand what was decided and what remains to be done.
- Support revoking future access and recording when access was granted or used.

### Important technical and privacy limits

- An MI code alone cannot make ChatGPT, OpenAI, or another AI provider access private account memories, hidden chats, or data stored inside a different provider. Each provider controls its own account data and permissions.
- Cross-platform memory transfer must use user-authorized exports, uploads, or officially supported integrations/APIs. The system must never claim it can read every AI account automatically.
- An MI code should identify a memory item or workspace; it must not act as the only password or security factor. Require account authentication and explicit permission before revealing private data.
- Private memory should be encrypted in transit and at rest, with owner-controlled access, selective sharing, access logs, backups, and a way to revoke future access.
- The assistant should receive only the minimum context needed for the task, not the owner's entire private archive by default.
- Linking multiple accounts must not merge all private chats automatically; each account must be authorized separately and shared data must be selected by the owner.

## Important access limitation

Revoking access can prevent future access through this platform, but cannot guarantee deletion of copies that someone has already downloaded, copied, or captured.

## Cost and security principles

- Prefer free tools and services while the project is being developed.
- Never publish API keys, passwords, or private credentials in website code or this repository.
- Explain clearly when a feature is a prototype, planned, or fully working.

### Chosen account model: MI ACCOUNT LINK

The owner will use one MI MEMORY workspace and link both of their own ChatGPT identities to it through separate authorization flows. Both linked identities can access the same owner-approved projects and memory collections. Private collections remain private unless the owner explicitly shares them. Each linked identity can be disconnected or have its access revoked independently. Linking does not grant automatic access to private ChatGPT chats or hidden account memories; supported exports or integrations and explicit permissions are required.
