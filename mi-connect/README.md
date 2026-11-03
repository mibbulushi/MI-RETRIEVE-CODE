# MI CONNECT

MI CONNECT is a separate, installable integration tool for the MI-RETRIEVE-AI ecosystem.

It is maintained in its own folder so it can later be extracted into a separate repository or deployed as an independent service, while remaining connected to the main MI-RETRIEVE-CODE project.

## Purpose

MI CONNECT lets compatible AI platforms request information from a user's MI workspace, only after the user has authenticated and granted permission.

## Planned capabilities

- Connect compatible AI clients through the Model Context Protocol (MCP).
- Verify the user's identity through a secure sign-in flow.
- Retrieve a project by MI reference code after authorization.
- Search the user's permitted projects.
- Save or update information only after explicit user approval.
- Respect project-level sharing permissions and revocation.
- Keep an access log so users can review connections and actions.

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

This directory is the initial specification for the separate MI CONNECT tool. It is not yet a live MCP server and cannot currently connect to ChatGPT or retrieve private projects.

## Build sequence

1. Define the MI account and project API in the main MI service.
2. Implement the MCP server and its tool definitions.
3. Add secure sign-in, permission scopes, and access revocation.
4. Connect the MCP server to the MI project database.
5. Deploy the server to a stable public HTTPS endpoint.
6. Test with a compatible AI client and verify that private data is never returned without authorization.

## OpenAI integration

OpenAI's Apps SDK uses MCP for ChatGPT app integrations. Availability of custom MCP connections and write actions depends on the ChatGPT plan and workspace controls. See the official documentation:

- https://developers.openai.com/apps-sdk/
- https://developers.openai.com/plugins/build/app-quickstart
- https://help.openai.com/en/articles/12584461-developer-mode-and-full-mcp-connectors-in-chatgpt

MI CONNECT is intended to support other AI clients that implement MCP as well; each client has its own connection and permission requirements.
