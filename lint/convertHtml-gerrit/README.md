# convertHtml-gerrit

A variant of [`../convertHtml`](../convertHtml) used by the Gerrit CI runner for
the `localization-data` repository (`run-test.sh`, invoked from Jenkins). It
reads the per-app `<app>-result.json` files produced by `webOSJsonFormatter` and
renders a self-contained HTML report (CSS/JS inlined).

## Why a separate copy

The original `convertHtml/convertHtml.js` assumes it is run from this repo's
root: it loads its own assets from `process.cwd()/convertHtml/`. The Gerrit
runner lives in a different repository and invokes the converter from *that*
repo's root, so the cwd-relative asset path does not resolve.

Rather than patch the shared copy (and risk breaking the standalone
`execute-lint.sh` flow that depends on the cwd behavior), this folder holds a
small, self-contained fork. It differs from `../convertHtml/convertHtml.js` in
three ways only:

1. **ESM (`.mjs`)** — uses `import` instead of `require`, so it can resolve its
   own location via `import.meta.url`.
2. **cwd-independent assets** — assets load from `ASSET_DIR` (the module's own
   directory, from `import.meta.url`) instead of `process.cwd()/convertHtml/`.
   The runner can call it from anywhere; the four files just need to sit
   together in this folder.
3. **Skips the aggregate file** — the Gerrit runner writes a `total-result.json`
   (a cross-app summary with a different schema than the per-app results) into
   the same result directory. The converter skips that filename so it does not
   try to render a page from it.

Everything else — layout, styling, the `case-filter.js` / `rule-filter.js`
behavior — is identical to `../convertHtml`.

## Files

| File | Role |
| --- | --- |
| `convertHtml.mjs` | Entry point: JSON lint results → HTML report |
| `style.css` | Report stylesheet (inlined into the output) |
| `case-filter.js` | Summary-page toggle to hide apps with no issues |
| `rule-filter.js` | Per-rule (issue-type) filtering UI |

## Usage

```bash
node convertHtml.mjs -d <json-result-dir> -o <html-output-dir>
```

Requires `options-parser` (see this folder's sibling `../package.json`).

## Consumed by

`localization-data`'s `run-test.sh` sparse-checks-out just this folder at report
time and runs `convertHtml.mjs` against its lint results. Pinning that runner to
a specific commit of this repo keeps report output reproducible.
