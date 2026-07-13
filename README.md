# ilib-webos-utils

Utility scripts for webOS i18n/l10n tasks, built around two tools:

- [ilib-lint](https://github.com/iLib-js/ilib-mono/tree/main/packages/ilib-lint) — lints localization data and generates HTML reports (see [`lint/`](lint/README.md)).
- [loctool](https://github.com/iLib-js/ilib-mono/tree/main/packages/loctool) — drives XLIFF processing such as deleting, splitting, merging, and comparing translation units (see [`loctool/`](loctool/)).

## Contents

| Directory | Description |
|-----------|-------------|
| [`lint/`](lint/README.md) | Runs `ilib-lint` on localization data and generates HTML reports |
| [`loctool/xliff_delete_units/`](loctool/xliff_delete_units/README.md) | Utilities for deleting translation units from XLIFF files using loctool criteria |
| [`loctool/xliff_split_merge/`](loctool/xliff_split_merge/README.md) | Utilities for splitting/merging XLIFF files using loctool |
| [`loctool/xliff_compare/`](loctool/xliff_compare/README.md) | Compares two XLIFF directory trees and outputs modified/added/deleted differences |


## License

Apache 2.0 — see [LICENSE](LICENSE).
