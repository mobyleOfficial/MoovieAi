# patches/

Local patches applied to `node_modules/` via [`patch-package`](https://github.com/ds300/patch-package). Re-applied automatically on every `npm install` by the root `postinstall` script (`patch-package --error-on-fail`).

## Active patches

### `linear-mcp+1.2.0.patch`

**Why it exists**

`linear-mcp@1.2.0` (`dvcrn/linear-mcp`) initializes its Linear client via:

```js
new LinearClient({ accessToken: <PAT> })
```

`@linear/sdk@38`'s `parseClientOptions` always wraps `accessToken` in an `Authorization: Bearer …` header. Linear's API rejects PATs presented with a Bearer prefix:

```
It looks like you're trying to use an API key as a Bearer token.
Remove the Bearer prefix from the Authorization header.
```

The SDK's `apiKey` field yields a bare `Authorization: <token>` header, which is what PATs need. The patch flips the PAT branch of `LinearAuth.initialize()` to use `apiKey: config.accessToken`.

**Upstream tracking**

PR pending against `dvcrn/linear-mcp` proposing the equivalent fix upstream. The patch stays in tree until that PR (or a follow-up release of `linear-mcp`) lands the change.

**Exit criterion**

1. Upstream `linear-mcp` ships a release with the `apiKey` fix.
2. Bump `linear-mcp` in `package.json` to that release.
3. Delete `patches/linear-mcp+1.2.0.patch`.
4. Change `"linear-mcp": "1.2.0"` back to a caret range (e.g. `"^1.2.0"`).

## Editing rules

- The filename version (`linear-mcp+<X.Y.Z>.patch`) and the `package.json` pin MUST move together. `patch-package` resolves the patch by the installed package version; mismatched names will fail the install loudly (via `--error-on-fail`).
- To regenerate a patch after editing `node_modules/linear-mcp/`: `npx patch-package linear-mcp` (will overwrite the existing patch file).
- New patches go through the same workflow: edit the file under `node_modules/`, run `npx patch-package <pkg-name>`, commit the resulting `patches/<pkg>+<version>.patch`.
