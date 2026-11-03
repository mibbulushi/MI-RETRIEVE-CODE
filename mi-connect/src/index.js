import { McpServer } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";

const SERVER_VERSION = "0.1.0";

function createServer() {
  const server = new McpServer({ name: "mi-connect", version: SERVER_VERSION });

  server.registerTool(
    "mi_server_status",
    {
      description:
        "Return non-sensitive MI CONNECT prototype status. This tool never reads account or project data.",
      inputSchema: z.object({}),
    },
    async () => ({
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              service: "MI CONNECT",
              status: "prototype",
              transport: "stdio",
              miApiConnected: false,
              authenticationImplemented: false,
              privateProjectAccess: "disabled",
              nextStep:
                "Define the MI API and implement authenticated, explicitly authorized access before returning private project data.",
            },
            null,
            2,
          ),
        },
      ],
    }),
  );

  server.registerTool(
    "mi_retrieve_project",
    {
      description:
        "Prototype placeholder. An MI reference code is an identifier, not a password or proof of ownership. Retrieval is intentionally disabled until the MI API, user authentication, explicit read permission, and revocation checks exist.",
      inputSchema: z.object({
        referenceCode: z.string().trim().min(1).max(120),
      }),
    },
    async () => ({
      content: [
        {
          type: "text",
          text:
            "Project retrieval is disabled in this prototype. No MI API was called and no private project data was accessed or returned. An MI reference code identifies an item only; it does not authenticate a user or grant access.",
        },
      ],
      isError: true,
    }),
  );

  return server;
}

void serveStdio(createServer);
console.error(
  "MI CONNECT prototype started over stdio. Private project access is disabled.",
);
