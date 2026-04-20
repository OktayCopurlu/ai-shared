# on-frontend URLs

Shared URL and preview authentication conventions for on-frontend work.

## Environments

- **Local dev**: `http://localhost:5050`
- **Production**: `https://www.on.com`
- **Staging / Preview**: Use HTTP basic auth with credentials from `~/.ai-shared/.secrets`

## Preview Authentication

For staging or preview URLs:

- read `STAGING_USER` and `STAGING_PASS` from `~/.ai-shared/.secrets`
- do not look for credentials in the target project repo
- embed credentials directly in the URL

Format:

```text
https://<STAGING_USER>:<STAGING_PASS>@on-shop-<PR_NUMBER>.on-running.com/...
```

## Examples

- `https://www.on.com/en-ch/shop/mens/low` → `http://localhost:5050/en-ch/shop/mens/low`
- `https://www.on.com/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851` → `http://localhost:5050/en-ch/products/cloudflow-5-m-3mf1011/mens/juniper-ice-shoes-3MF10114851`
- Preview root: `https://<STAGING_USER>:<STAGING_PASS>@on-shop-8895.on-running.com/`
- Preview page: `https://<STAGING_USER>:<STAGING_PASS>@on-shop-8895.on-running.com/en-ch/products/...`

## Rules

- Treat `~/.ai-shared/.secrets` as the source of truth even when the current workspace is another repo
- Never hardcode credentials in skills, prompts, or checked-in project files
