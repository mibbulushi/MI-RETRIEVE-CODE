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

A local stdio MCP prototype now exists there. It can report non-sensitive server status, but project retrieval is deliberately disabled. There is no connection to the MI account API or private project data, no authentication or permission flow yet, no public deployment, and no ChatGPT connection.

## Build sequence

1. Define the MI account and project API in the main MI service.
2. Complete and test the local MCP server prototype in `../mi-connect/`.
3. Add secure sign-in, permission scopes, and access revocation.
4. Connect the MCP server to the MI project database.
5. Deploy the server to a stable public HTTPS endpoint.
6. Test with a compatible AI client and verify that private data is never returned without authorization.

## OpenAI integration

OpenAI's Apps SDK uses MCP for ChatGPT app integrations. Availability of custom MCP connections and write actions depends on the ChatGPT plan and workspace controls. See the official documentation:

- https://developers.openai.com/apps-sdk/
- https://developers.openai.com/api/docs/guides/tools-connectors-mcp
- https://help.openai.com/en/articles/12584461-developer-mode-and-full-mcp-connectors-in-chatgpt

MI MEMORY is intended to support other AI clients that implement MCP as well; each client has its own connection and permission requirements.

## Important limitation

No MI code can automatically read private memories, hidden chats, or account data from ChatGPT or another provider. Cross-platform transfer requires the owner's authorized export, upload, or an officially supported integration/API.
