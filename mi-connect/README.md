# MI CONNECT

MI CONNECT is the MCP integration component for **MI MEMORY**, the separate personal memory product in this ecosystem. The product name remains MI MEMORY; this folder contains the connector/server code and can later be extracted or deployed independently.

## Current implementation

**Prototype — local stdio only**

The first MCP server scaffold is now in `src/index.js`.

It exposes two tools:

- `mi_server_status` — returns non-sensitive prototype status only.
- `mi_retrieve_project` — accepts an MI reference code but deliberately returns an error. It does not call an API or return project data.

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

To inspect the available tools locally:

```bash
npx @modelcontextprotocol/inspector node src/index.js
```

The server writes its startup message to stderr so it does not interfere with MCP messages on stdout.

## What is not connected yet

- No MI account or project API exists in this server integration.
- No database, cloud storage, or cross-device retrieval is connected.
- User sign-in, OAuth, permission scopes, access logs, and revocation are not implemented.
- Project retrieval, search, saving, and updating are not active.
- No HTTP/HTTPS endpoint is configured or deployed.
- It is not connected to ChatGPT or another AI platform yet.

Do not treat the presence of an MCP tool name as proof that the feature is operational. The retrieval tool is intentionally fail-closed until the security and API work is complete.

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

1. Define the main MI account and project API contract (including owner IDs, project IDs, and permission checks).
2. Select and implement the account authentication and authorization flow.
3. Connect the retrieval tool to the API with read-only scopes first.
4. Add audit logging, client disconnection, and access revocation.
5. Add write tools only after explicit approval and separate write scopes are enforced.
6. Add a remote Streamable HTTP transport only after HTTPS, origin protections, and authorization are ready.
7. Test with the MCP Inspector and a compatible client before considering deployment.

## Official development references

- MCP TypeScript SDK v2 — first server: https://ts.sdk.modelcontextprotocol.io/v2/get-started/first-server
- MCP TypeScript SDK v2 — server documentation: https://ts.sdk.modelcontextprotocol.io/v2/
- OpenAI Apps SDK: https://developers.openai.com/apps-sdk/
- ChatGPT MCP connection availability and controls: https://help.openai.com/en/articles/12584461-developer-mode-and-full-mcp-connectors-in-chatgpt

MI CONNECT is intended to support other compatible MCP clients too. Each client has its own installation, connection, and permission requirements. MI MEMORY remains the name of the personal memory product.
