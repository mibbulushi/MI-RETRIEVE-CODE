# MI CONNECT

MI CONNECT is the MCP integration component for **MI MEMORY**, the separate personal memory product in this ecosystem. The product name remains MI MEMORY; this folder contains the connector/server code and can later be extracted or deployed independently.

## Current implementation

**Prototype — local stdio only**

The first MCP server scaffold is now in `src/index.js`.

It exposes two tools:

- `mi_server_status` — returns non-sensitive prototype status only.
- `mi_retrieve_project` — accepts an MI reference code but deliberately returns an error. It does not call an API or return project data.

A separate helper, `src/access-policy.js`, now evaluates a future read request against trusted owner identity, active account-link status, least-privilege read permissions, an explicit per-project share, and optional expiry. Eleven Node built-in tests cover allow/deny cases, including account-level revocation and cross-account/project mismatches. This helper is **not connected to the MCP retrieval tool** and does not authenticate anyone, fetch data, or write audit logs.

The server uses the official MCP TypeScript SDK v2 server package and Zod input validation. It uses the standard input/output (stdio) transport, so a compatible local AI client must launch the process. There is no public web address or remote endpoint.

## Run locally

Requirements:

- Node.js 20 or later (use a currently supported, security-updated release).
- npm.

From this folder:

```bash
npm install
npm start
```

Run the standalone authorization-policy tests:

```bash
npm test
```

To inspect the available MCP tools locally:

```bash
npx @modelcontextprotocol/inspector node src/index.js
```

The policy tests use Node's built-in test runner. The server writes its startup message to stderr so it does not interfere with MCP messages on stdout.

## What is not connected yet

- No MI account or project API exists in this server integration.
- No database, cloud storage, or cross-device retrieval is connected.
- User sign-in, OAuth, production permission enforcement, server-side audit logs, and real account-link revocation are not implemented.
- The standalone policy helper is not wired to trusted authentication/API records or to the MCP tools.
- Project retrieval, search, saving, and updating are not active.
- No HTTP/HTTPS endpoint is configured or deployed.
- It is not connected to ChatGPT or another AI platform yet.

Do not treat the presence of an MCP tool name as proof that the feature is operational. The retrieval tool is intentionally fail-closed until the security and API work is complete.

## MI ACCOUNT LINK model

One MI MEMORY owner workspace may link two or more of the owner's own AI accounts. Each account must be authorized separately and can be disconnected independently. Memory remains private by default; the owner must explicitly grant a selected project and read scope to a specific linked account. Do not automatically merge private chats. Never ask for or store provider passwords.

For a future API integration, the policy helper's identity, link, project-owner, and share-grant fields must be loaded from verified authentication claims and trusted server-side records—not accepted from MCP arguments. Each successful or denied private-data request must later be recorded in an audit log. Those authentication, data-loading, and audit components are still pending.

## Security rules

- An MI reference code is an identifier only. It is not a password, access token, or proof of ownership.
- Never return private data until the user has authenticated and explicitly granted the required permission.
- Check project-level permissions and whether access has been revoked on every private-data request.
- Keep read and write permissions separate; require explicit approval for write actions.
- Keep credentials outside source control, using environment variables or a secret manager when authentication is implemented.
- Use HTTPS and a supported authorization flow before offering remote access.
- Request only the minimum data and permission needed for a task.
- Revoking future access cannot erase copies already downloaded or captured elsewhere.

The current retrieval placeholder returns no private data, even if a caller supplies a reference code.

## Next build steps

1. Define the MI account/project API contract and trusted data model for linked accounts, selected project grants, and audit events.
2. Implement secure account authentication and authorization; never accept identity or grants from tool arguments.
3. Wire `evaluateProjectReadAccess` to the authenticated API adapter and fail closed on any missing or revoked record.
4. Add server-side audit logging and account-level disconnect/revocation checks on every private-data request.
5. Connect retrieval with read-only scopes first; add writes only after explicit approval and separate write scopes are enforced.
6. Add remote Streamable HTTP transport only after HTTPS, origin protections, and authorization are ready.
7. Test with the MCP Inspector and a compatible client before considering deployment.

## Official development references

- MCP TypeScript SDK v2 — first server: https://ts.sdk.modelcontextprotocol.io/v2/get-started/first-server
- MCP TypeScript SDK v2 — server documentation: https://ts.sdk.modelcontextprotocol.io/v2/
- OpenAI Apps SDK: https://developers.openai.com/apps-sdk/
- ChatGPT MCP connection availability and controls: https://help.openai.com/en/articles/12584461-developer-mode-and-full-mcp-connectors-in-chatgpt

MI CONNECT is intended to support other compatible MCP clients too. Each client has its own installation, connection, and permission requirements. MI MEMORY remains the name of the personal memory product.
