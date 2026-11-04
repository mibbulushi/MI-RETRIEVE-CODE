# MI MEMORY

**MI MEMORY** is a separate personal memory and integration tool within the MI-RETRIEVE-CODE ecosystem.

Full name: **Universal Personal AI Memory System**.

It is maintained in its own folder so it can later be extracted into a separate repository or deployed independently, while remaining connected to the main MI platform.

## Purpose

MI MEMORY helps the owner preserve, organize, search, and reuse their information and project history across compatible AI assistants, only through user-authorized imports or secure connections.

## Planned capabilities

- Connect compatible AI clients through the Model Context Protocol (MCP).
- Import conversation exports and user-selected content from services that support export or integration.
- Verify the user's identity through a secure sign-in flow.
- Retrieve a project by MI reference code after authorization.
- Search the user's permitted projects.
- Save or update information only after explicit user approval.
- Respect project-level sharing permissions and revocation.
- Keep an access log so users can review connections and actions.

## Multi-account support (planned)

MI MEMORY should let one owner securely connect two or more of their own AI accounts (for example, two ChatGPT accounts) to the same MI MEMORY workspace.

- Provide a separate, explicit sign-in/authorization flow for each account; never ask users to share account passwords.
- Let the owner name each connected account and view, disconnect, or revoke it independently.
- Allow the owner to choose which projects or memory collections are shared with each account.
- Support optional sharing of selected information between the owner's linked accounts, with clear confirmation before data is copied or updated.
- Keep account-specific data private by default; linking accounts must not automatically merge all chats or memories.
- Record which connected account accessed or changed each item, with timestamps and an audit history.
- Prevent one linked account from granting access to unrelated users or accounts without the owner's approval.

This feature depends on secure account authentication and supported provider exports or integrations. Linking two accounts does not give MI MEMORY automatic access to private chats or hidden memories in either provider.

## Security requirements

- An MI reference code is an identifier, not a password or proof of ownership.
- Require account authentication and authorization before returning private data.
- Never expose private projects to another user merely because they know a code, email address, or display name.
- Use HTTPS for deployed endpoints and OAuth 2.1 or another supported secure authorization flow.
- Store credentials and signing secrets outside source control in environment variables or a secret manager.
- Request the minimum permissions needed. Separate read access from write access.
- Let users disconnect an AI client and revoke its access.
- Explain that revoking access cannot erase copies already downloaded or captured outside MI.

## Current status

This folder documents the MI MEMORY product. Its MCP integration component is maintained in the sibling `mi-connect/` folder.

A local stdio MCP prototype now exists there. It can report non-sensitive server status, but project retrieval is deliberately disabled. A standalone fail-closed read-policy helper and 11 automated tests have been added for the future MI ACCOUNT LINK authorization checks; the helper is not wired to real authentication, API records, retrieval, or audit logging. There is no connection to private project data, no production authentication or permission flow, no public deployment, and no ChatGPT connection.

## Build sequence

1. Define the MI account/project API and server-side records for linked accounts, project-specific grants, and audit events.
2. Implement secure sign-in for each linked AI account without collecting provider passwords.
3. Wire and enforce the read-policy helper using verified identity claims and trusted API records.
4. Add server-side audit logging and independent account/grant revocation.
5. Connect retrieval to the MI project database with read-only permissions first.
6. Test with the MCP Inspector and a compatible client; only then consider deployment.

## OpenAI integration

OpenAI's Apps SDK uses MCP for ChatGPT app integrations. Availability of custom MCP connections and write actions depends on the ChatGPT plan and workspace controls. See the official documentation:

- https://developers.openai.com/apps-sdk/
- https://developers.openai.com/api/docs/guides/tools-connectors-mcp
- https://help.openai.com/en/articles/12584461-developer-mode-and-full-mcp-connectors-in-chatgpt

MI MEMORY is intended to support other AI clients that implement MCP as well; each client has its own connection and permission requirements.

## Important limitation

No MI code can automatically read private memories, hidden chats, or account data from ChatGPT or another provider. Cross-platform transfer requires the owner's authorized export, upload, or an officially supported integration/API.

## Chosen account model: MI ACCOUNT LINK

The product decision is to use **one MI MEMORY owner account/workspace** with **two or more separately authorized personal AI identities** linked to it. For the owner's two ChatGPT identities:

- Both identities point to the same MI MEMORY workspace; the owner does not need to maintain duplicate memory accounts.
- Both can access the same projects and memory collections that the owner has approved for shared access.
- Collections and items remain private by default unless the owner explicitly shares them.
- Each identity has its own connection record, permissions, access history, and independent disconnect/revocation control.
- The owner can change sharing permissions later; one identity cannot silently expand the other's access.
- Provider-side private chats and hidden memories are not automatically available. Import or access requires an owner-authorized export or a supported provider integration.

The feature name shown in the product is **MI ACCOUNT LINK**. It is a linking feature inside MI MEMORY, not a separate memory database.
