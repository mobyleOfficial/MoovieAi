#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";
import { promises as fs } from "fs";
import path from "path";

const ROOT_DIR = process.cwd();

type ToolHandler = (args: Record<string, string>) => Promise<string>;

const handlers: Record<string, ToolHandler> = {
  "sync-submodule": async (args) => {
    const { name } = args;
    if (!name) throw new Error("name parameter required");

    const submodulePath = path.join(ROOT_DIR, name);
    try {
      await fs.access(submodulePath);
    } catch {
      throw new Error(`Submodule '${name}' not found at ${submodulePath}`);
    }

    execSync("git submodule update --remote", {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    const commit = execSync(`git -C ${name} rev-parse --short HEAD`, {
      cwd: ROOT_DIR,
      encoding: "utf-8",
    }).trim();

    execSync(`git add ${name}`, { cwd: ROOT_DIR, stdio: "pipe" });

    const status = execSync("git status --porcelain", {
      cwd: ROOT_DIR,
      encoding: "utf-8",
    });

    if (!status.includes(name)) {
      return `✓ Submodule '${name}' already up to date (${commit})`;
    }

    execSync(`git commit -m "chore: update ${name} submodule reference"`, {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    return `✓ Synced '${name}' to ${commit}`;
  },

  "create-feature-branch": async (args) => {
    const { name } = args;
    if (!name) throw new Error("name parameter required");

    await handlers["sync-submodule"]({ name: "moovie" });
    await handlers["sync-submodule"]({ name: "backend" });

    execSync("git checkout develop || git checkout dev", {
      cwd: ROOT_DIR,
      stdio: "pipe",
      shell: "/bin/bash",
    } as never);
    execSync("git pull", { cwd: ROOT_DIR, stdio: "pipe" });

    const branchName = `feature/${name}`;
    execSync(`git checkout -b ${branchName}`, {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    return `✓ Created feature branch '${branchName}' (submodules synced)`;
  },

  "create-release-branch": async (args) => {
    const { version } = args;
    if (!version) throw new Error("version parameter required");

    await handlers["sync-submodule"]({ name: "moovie" });
    await handlers["sync-submodule"]({ name: "backend" });

    execSync("git checkout develop || git checkout dev", {
      cwd: ROOT_DIR,
      stdio: "pipe",
      shell: "/bin/bash",
    } as never);
    execSync("git pull", { cwd: ROOT_DIR, stdio: "pipe" });

    const branchName = `release/${version}`;
    execSync(`git checkout -b ${branchName}`, {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    return `✓ Created release branch '${branchName}' (submodules synced)`;
  },

  "open-pull-request": async (args) => {
    const { title, description } = args;
    if (!title) throw new Error("title parameter required");

    const branch = execSync("git rev-parse --abbrev-ref HEAD", {
      cwd: ROOT_DIR,
      encoding: "utf-8",
    }).trim();

    let baseRef = "main";
    if (branch.startsWith("feature/") || branch.startsWith("fix/")) {
      baseRef = "develop";
    } else if (branch.startsWith("release/")) {
      baseRef = "main";
    }

    execSync(`git push -u origin ${branch}`, {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    const ghArgs = [`--title ${JSON.stringify(title)}`, `--base ${baseRef}`];
    if (description) {
      ghArgs.push(`--body ${JSON.stringify(description)}`);
    }
    execSync(`gh pr create ${ghArgs.join(" ")}`, {
      cwd: ROOT_DIR,
      stdio: "pipe",
    });

    return `✓ PR created: ${branch} → ${baseRef}`;
  },

  "check-status": async () => {
    const moovieStatus = execSync(
      "git -C moovie rev-parse HEAD && git -C moovie rev-parse origin/main",
      { cwd: ROOT_DIR, encoding: "utf-8" }
    );
    const backendStatus = execSync(
      "git -C backend rev-parse HEAD && git -C backend rev-parse origin/main",
      { cwd: ROOT_DIR, encoding: "utf-8" }
    );

    const moovieLines = moovieStatus.trim().split("\n");
    const backendLines = backendStatus.trim().split("\n");

    const moovieStale = moovieLines[0] !== moovieLines[1];
    const backendStale = backendLines[0] !== backendLines[1];

    let status = "Submodule Status:\n";
    status += `  moovie:  ${moovieStale ? "⚠ STALE" : "✓ up to date"}\n`;
    status += `  backend: ${backendStale ? "⚠ STALE" : "✓ up to date"}`;
    return status;
  },
};

const toolDefinitions = [
  {
    name: "sync-submodule",
    description:
      "Sync a submodule to the latest remote commit and update the reference",
    inputSchema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Submodule name (moovie or backend)",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "create-feature-branch",
    description:
      "Sync submodules, checkout develop, and create a feature branch",
    inputSchema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Feature name (becomes feature/name)",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "create-release-branch",
    description:
      "Sync submodules, checkout develop, and create a release branch",
    inputSchema: {
      type: "object",
      properties: {
        version: {
          type: "string",
          description: "Version number (becomes release/version)",
        },
      },
      required: ["version"],
    },
  },
  {
    name: "open-pull-request",
    description:
      "Create a pull request (feature/fix branches → develop, release branches → main)",
    inputSchema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "PR title (use Conventional Commits format)",
        },
        description: {
          type: "string",
          description: "PR description (optional)",
        },
      },
      required: ["title"],
    },
  },
  {
    name: "check-status",
    description: "Check which submodules are stale or up to date",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
  },
];

const server = new Server(
  { name: "repo-management", version: "1.1.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: toolDefinitions,
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const handler = handlers[name];
  if (!handler) {
    return {
      content: [{ type: "text", text: `Unknown tool: ${name}` }],
      isError: true,
    };
  }
  try {
    const result = await handler((args ?? {}) as Record<string, string>);
    return { content: [{ type: "text", text: result }] };
  } catch (error) {
    return {
      content: [
        { type: "text", text: (error as Error).message || String(error) },
      ],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
