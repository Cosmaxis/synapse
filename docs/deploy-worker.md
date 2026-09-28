# Deploying the install Worker

`worker.js` serves the stable install URL: `https://synapse.cosmaxis.com/install`
proxies `install.sh` from the latest release tag (falling back to `main`).

## Deploy

```sh
npx wrangler deploy
```

Same shape as 9routerx: `wrangler.toml` declares only `name`, `main`, and
`compatibility_date`. No bindings, no build step.

## Custom domain

`synapse.cosmaxis.com` must point at the Worker. Either path works, pick one:

- **Dashboard** — Workers & Pages → `synapse` → Settings → Domains & Routes →
  Add → Custom Domain → `synapse.cosmaxis.com`. Cloudflare creates the DNS
  record and cert automatically. `cosmaxis.com` must already be a zone on the
  same account.
- **CLI** — add to `wrangler.toml`:

  ```toml
  routes = [
    { pattern = "synapse.cosmaxis.com", custom_domain = true }
  ]
  ```

  then `npx wrangler deploy`.

Verify:

```sh
curl -sfS https://synapse.cosmaxis.com/          # help text + resolved version
curl -sfS https://synapse.cosmaxis.com/install | head -5
```

## Credentials you must supply

Wrangler needs these; nobody can generate them for you.

| Name | What it is | Where to get it |
| --- | --- | --- |
| `CLOUDFLARE_API_TOKEN` | API token used to publish the Worker and manage its route | Cloudflare dashboard → My Profile → API Tokens → Create Token → **Edit Cloudflare Workers** template, scoped to the `cosmaxis.com` zone |
| `CLOUDFLARE_ACCOUNT_ID` | Account that owns the Worker | Cloudflare dashboard → Workers & Pages → Account ID (right sidebar) |

Local deploy: export both as env vars (or run `npx wrangler login` instead of
the token, which covers `CLOUDFLARE_API_TOKEN` only — the account ID is still
needed if you own more than one account).

If you ever automate deploys from GitHub Actions, store both as repository
secrets under the same names. No values are recorded in this repo.
