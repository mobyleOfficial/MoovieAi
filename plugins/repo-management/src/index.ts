import { execSync } from "child_process";
import { promises as fs } from "fs";
import path from "path";

interface Tool {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties: Record<string, unknown>;
    required: string[];
  };
}

// Get the root directory (MoovieAi/)
const ROOT_DIR = process.cwd();

// Tool implementations
const tools: Record<string, (args: Record<string, string>) => Promise<string>> =
  {
    "sync-submodule": async (args) => {
      const { name } = args;
      if (!name) throw new Error("name parameter required");

      const submodulePath = path.join(ROOT_DIR, name);

      // Verify submodule exists
      try {
        await fs.access(submodulePath);
      } catch {
        throw new Error(`Submodule '${name}' not found at ${submodulePath}`);
      }

      try {
        // Fetch latest from remote
        execSync("git submodule update --remote", {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        // Get current commit hash
        const commit = execSync(
          `cd ${name} && git rev-parse --short HEAD`,
          {
            cwd: ROOT_DIR,
            encoding: "utf-8",
          }
        ).trim();

        // Stage the submodule reference change
        execSync(`git add ${name}`, { cwd: ROOT_DIR, stdio: "pipe" });

        // Check if there are changes to commit
        const status = execSync("git status --porcelain", {
          cwd: ROOT_DIR,
          encoding: "utf-8",
        });

        if (!status.includes(name)) {
          return `✓ Submodule '${name}' already up to date (${commit})`;
        }

        // Commit with conventional format
        execSync(
          `git commit -m "chore: update ${name} submodule reference"`,
          {
            cwd: ROOT_DIR,
            stdio: "pipe",
          }
        );

        return `✓ Synced '${name}' to ${commit}`;
      } catch (error) {
        throw new Error(
          `Failed to sync submodule '${name}': ${(error as Error).message}`
        );
      }
    },

    "create-feature-branch": async (args) => {
      const { name } = args;
      if (!name) throw new Error("name parameter required");

      try {
        // Sync first
        await tools["sync-submodule"]({
          name: "moovie",
        });
        await tools["sync-submodule"]({
          name: "backend",
        });

        // Checkout develop
        execSync("git checkout develop || git checkout dev", {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        // Pull latest
        execSync("git pull", { cwd: ROOT_DIR, stdio: "pipe" });

        // Create feature branch
        const branchName = `feature/${name}`;
        execSync(`git checkout -b ${branchName}`, {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        return `✓ Created feature branch '${branchName}' (submodules synced)`;
      } catch (error) {
        throw new Error(
          `Failed to create feature branch: ${(error as Error).message}`
        );
      }
    },

    "create-release-branch": async (args) => {
      const { version } = args;
      if (!version) throw new Error("version parameter required");

      try {
        // Sync first
        await tools["sync-submodule"]({
          name: "moovie",
        });
        await tools["sync-submodule"]({
          name: "backend",
        });

        // Checkout develop
        execSync("git checkout develop || git checkout dev", {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        // Pull latest
        execSync("git pull", { cwd: ROOT_DIR, stdio: "pipe" });

        // Create release branch
        const branchName = `release/${version}`;
        execSync(`git checkout -b ${branchName}`, {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        return `✓ Created release branch '${branchName}' (submodules synced)`;
      } catch (error) {
        throw new Error(
          `Failed to create release branch: ${(error as Error).message}`
        );
      }
    },

    "open-pull-request": async (args) => {
      const { title, description } = args;
      if (!title) throw new Error("title parameter required");

      try {
        // Get current branch name
        const branch = execSync("git rev-parse --abbrev-ref HEAD", {
          cwd: ROOT_DIR,
          encoding: "utf-8",
        }).trim();

        // Determine base branch
        let baseRef = "main";
        if (branch.startsWith("feature/") || branch.startsWith("fix/")) {
          baseRef = "develop";
        } else if (branch.startsWith("release/")) {
          baseRef = "main";
        }

        // Push current branch
        execSync(`git push -u origin ${branch}`, {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        // Create PR using gh CLI (auto-uses .github/pull_request_template.md)
        const ghArgs = [`--title "${title}"`, `--base ${baseRef}`];
        if (description) {
          ghArgs.push(`--body "${description}"`);
        }

        execSync(`gh pr create ${ghArgs.join(" ")}`, {
          cwd: ROOT_DIR,
          stdio: "pipe",
        });

        return `✓ PR created: ${branch} → ${baseRef}\nTemplate applied from .github/pull_request_template.md`;
      } catch (error) {
        throw new Error(
          `Failed to open PR: ${(error as Error).message}`
        );
      }
    },

    "check-status": async () => {
      try {
        const moovieStatus = execSync(
          "git -C moovie rev-parse HEAD && git -C moovie rev-parse origin/main",
          {
            cwd: ROOT_DIR,
            encoding: "utf-8",
          }
        );
        const backendStatus = execSync(
          "git -C backend rev-parse HEAD && git -C backend rev-parse origin/main",
          {
            cwd: ROOT_DIR,
            encoding: "utf-8",
          }
        );

        const moovieLines = moovieStatus.trim().split("\n");
        const backendLines = backendStatus.trim().split("\n");

        const moovieStale = moovieLines[0] !== moovieLines[1];
        const backendStale = backendLines[0] !== backendLines[1];

        let status = "Submodule Status:\n";
        status += `  moovie:  ${moovieStale ? "⚠ STALE" : "✓ up to date"}\n`;
        status += `  backend: ${backendStale ? "⚠ STALE" : "✓ up to date"}`;

        return status;
      } catch (error) {
        throw new Error(`Failed to check status: ${(error as Error).message}`);
      }
    },
  };

// Tool definitions for MCP
const toolDefinitions: Tool[] = [
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

// Main server loop (for testing/CLI usage)
if (import.meta.url === `file://${process.argv[1]}`) {
  console.log("repo-management MCP Server");
  console.log("Available tools:");
  toolDefinitions.forEach((tool) => {
    console.log(`  - ${tool.name}: ${tool.description}`);
  });
}
