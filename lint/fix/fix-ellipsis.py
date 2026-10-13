#!/usr/bin/env python3
"""
fix-ellipsis.py - Fix sentence-ending ellipsis mismatches reported by ilib-lint.

Part of the lint/fix/ family of report-driven auto-fix scripts: each takes an
ilib-lint category report and the localization-data root, then rewrites the
affected <target> texts in place.

Scope:
  Replace a trailing "..." (three ASCII dots, U+002E x3) with "…" (U+2026) in
  <target> text, for the (App, File, Source) entries in the ellipsis_mismatch
  report whose Description says
    should be "…" (U+2026) ... instead of "..." (U+002E U+002E U+002E)
  Other end-punctuation corrections present in the same report (e.g. "."->"…",
  "!"->"…", or reverse "…"->"...") are intentionally NOT handled here.

Matching key:
  Source text + target ending. A segment is fixed only when
    - its <source> text matches a reported Source for that app/file, AND
    - its <target> text ends with exactly "..." (three dots, not four or more).
  The unit "name" attribute is irrelevant (the report falls back to showing the
  Source as the Key when a unit has no name).

Layout (matches execute-lint.sh conventions):
  App  = top-level subdirectory of LOCDATA_PATH
  File = xliff file name inside that app directory

Safety:
  Dry-run by default - prints what WOULD change (counts + sample diffs) and any
  reported sources it could not match. Pass --apply to write files.

The script reads a LOCAL report file only; it does not download anything.
Fetch the report first with curl (see README.md), then point --report at it:

  curl -s "http://i18n.lge.com/ilib-lint/<run>/categories/ellipsis_mismatch-result.html" \\
      -o ellipsis_mismatch-result.html

Usage:
  # dry-run against a local report file
  python3 fix-ellipsis.py ~/Source/localization-data --report ./ellipsis_mismatch-result.html

  # actually apply
  python3 fix-ellipsis.py ~/Source/localization-data --report ./ellipsis_mismatch-result.html --apply

  # restrict to one app, and list unmatched sources
  python3 fix-ellipsis.py ~/Source/localization-data --report ./ellipsis_mismatch-result.html \\
      --limit-app account-billing --show-unmatched
"""

import argparse
import html
import os
import re
import sys
from collections import defaultdict

# ---- scope constants ---------------------------------------------------------
INSTEAD_CP = "U+002E U+002E U+002E"   # "..."
SHOULD_CP = "U+2026"                  # "…"
ELLIPSIS = "…"                   # …

# Replace a trailing "..." (exactly three dots, not preceded by another dot),
# allowing optional trailing whitespace which is preserved.
TRAILING_DOTS_RE = re.compile(r"(?<!\.)\.\.\.(\s*)$", re.S)

# One <source>..</source> immediately followed by <target>..</target>.
# Non-greedy; XLIFF targets never contain a nested </target>.
SEG_RE = re.compile(r"<source>(.*?)</source>(\s*)<target>(.*?)</target>", re.S)


def strip_tags(s: str) -> str:
    return re.sub(r"<[^>]+>", "", s)


def unesc(s: str) -> str:
    return html.unescape(s)


def field_raw(card: str, key: str):
    m = re.search(
        r'<td class="detail-key">' + re.escape(key) + r"</td><td[^>]*>(.*?)</td>",
        card,
        re.S,
    )
    return m.group(1) if m else None


def load_report(report: str) -> str:
    """Return report HTML text from a local file.

    Downloading is intentionally not handled here - fetch the report with curl
    first (see README.md). This keeps responsibilities clear: curl downloads,
    this script fixes.
    """
    if report.startswith("http://") or report.startswith("https://"):
        sys.exit(
            "This script does not download reports. Fetch the report with curl "
            "first, then pass the local file path:\n"
            f'  curl -s "{report}" -o ellipsis_mismatch-result.html\n'
            "  python3 fix-ellipsis.py <LOCDATA_PATH> --report ellipsis_mismatch-result.html"
        )
    if not os.path.isfile(report):
        sys.exit(f"Report file not found: {report}")
    with open(report, encoding="utf-8") as f:
        return f.read()


def parse_report(text: str):
    """Return (dict[(app, file)] -> set(source_text), in_scope, out_scope)."""
    cards = text.split('<div class="detail-card"')[1:]
    wanted = defaultdict(set)
    in_scope = 0
    out_scope = 0
    for c in cards:
        desc = unesc(strip_tags(field_raw(c, "Description") or ""))
        m = re.search(
            r'should be ".*?" \(([^)]*)\) for (\S+) locale instead of ".*?" \(([^)]*)\)',
            desc,
        )
        if not m:
            continue
        should_cp, _loc, instead_cp = m.groups()
        if should_cp == SHOULD_CP and instead_cp.strip().endswith(INSTEAD_CP):
            app = unesc(strip_tags(field_raw(c, "App") or ""))
            fil = unesc(strip_tags(field_raw(c, "File") or ""))
            src = unesc(strip_tags(field_raw(c, "Source") or ""))
            wanted[(app, fil)].add(src)
            in_scope += 1
        else:
            out_scope += 1
    return wanted, in_scope, out_scope


def fix_file(repo_root, app, fil, sources, apply):
    """Return (changed_count, unmatched_sources, samples) for one xliff file."""
    path = os.path.join(repo_root, app, fil)
    if not os.path.isfile(path):
        return 0, set(sources), [("<missing file>", path, "")]

    with open(path, encoding="utf-8") as f:
        text = f.read()

    changed = 0
    samples = []
    matched_sources = set()

    def repl(mobj):
        nonlocal changed
        src_raw, gap, tgt_raw = mobj.group(1), mobj.group(2), mobj.group(3)
        src_plain = unesc(strip_tags(src_raw))
        if src_plain not in sources:
            return mobj.group(0)
        if not TRAILING_DOTS_RE.search(tgt_raw):
            return mobj.group(0)
        new_tgt = TRAILING_DOTS_RE.sub(lambda mm: ELLIPSIS + mm.group(1), tgt_raw)
        if new_tgt == tgt_raw:
            return mobj.group(0)
        changed += 1
        matched_sources.add(src_plain)
        if len(samples) < 5:
            samples.append((src_plain, tgt_raw, new_tgt))
        return "<source>" + src_raw + "</source>" + gap + "<target>" + new_tgt + "</target>"

    new_text = SEG_RE.sub(repl, text)

    if apply and changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_text)

    unmatched = set(sources) - matched_sources
    return changed, unmatched, samples


def main():
    ap = argparse.ArgumentParser(
        description="Fix trailing '...' -> '…' in xliff targets from an ilib-lint ellipsis_mismatch report.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("locdata_path", help="Root directory of localization data (apps are its subdirectories)")
    ap.add_argument("--report", required=True, help="Path to a local ellipsis_mismatch report HTML file (download it first with fetch-report.sh; see README.md)")
    ap.add_argument("--apply", action="store_true", help="Write changes (default: dry-run)")
    ap.add_argument("--limit-app", default=None, help="Only process this app directory")
    ap.add_argument("--show-unmatched", action="store_true", help="List reported sources that could not be matched")
    args = ap.parse_args()

    repo = os.path.abspath(args.locdata_path)
    if not os.path.isdir(repo):
        sys.exit(f"LOCDATA_PATH is not a directory: {repo}")

    sz = os.path.getsize(args.report) if os.path.isfile(args.report) else 0
    print(f"Loading report ({sz / 1_000_000:.1f} MB): {args.report} ...", flush=True)
    text = load_report(args.report)
    print("Parsing report ...", flush=True)
    wanted, in_scope, out_scope = parse_report(text)
    if args.limit_app:
        wanted = {k: v for k, v in wanted.items() if k[0] == args.limit_app}

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"\n=== {mode} ===")
    print(f"LOCDATA_PATH: {repo}")
    print(f"In-scope issues (...->…): {in_scope}   out-of-scope skipped: {out_scope}")
    print(f"Files to process: {len(wanted)}")
    print()

    total_changed = 0
    total_unmatched = 0
    files_changed = 0
    sample_shown = 0
    unmatched_detail = defaultdict(set)

    targets = sorted(wanted)
    total_files = len(targets)
    show_progress = sys.stderr.isatty()  # live bar only on an interactive terminal

    def progress(done):
        if not show_progress:
            return
        pct = done * 100 // total_files if total_files else 100
        bar_w = 30
        filled = pct * bar_w // 100
        bar = "#" * filled + "-" * (bar_w - filled)
        sys.stderr.write(f"\r  [{bar}] {pct:3d}%  {done}/{total_files} files  "
                         f"({total_changed} changed)")
        sys.stderr.flush()

    for i, (app, fil) in enumerate(targets, 1):
        changed, unmatched, samples = fix_file(repo, app, fil, wanted[(app, fil)], args.apply)
        total_changed += changed
        total_unmatched += len(unmatched)
        if changed:
            files_changed += 1
        if unmatched:
            unmatched_detail[(app, fil)] = unmatched
        if samples and sample_shown < 15:
            if show_progress:
                sys.stderr.write("\r" + " " * 70 + "\r")  # clear progress line
                sys.stderr.flush()
            print(f"[{app}/{fil}] {changed} change(s)")
            for src, old, new in samples:
                if sample_shown >= 15:
                    break
                print(f"    src : {src!r}")
                print(f"    old : {old[-50:]!r}")
                print(f"    new : {new[-50:]!r}")
                sample_shown += 1
            print()
        # update the live bar every 50 files (and on the last one)
        if i % 50 == 0 or i == total_files:
            progress(i)

    if show_progress:
        sys.stderr.write("\n")
        sys.stderr.flush()

    print("=== SUMMARY ===")
    print(f"targets changed : {total_changed}")
    print(f"files changed   : {files_changed}")
    print(f"unmatched srcs  : {total_unmatched} (reported but no target ending in exactly '...' found)")

    if args.show_unmatched and unmatched_detail:
        print("\n=== UNMATCHED (first 40) ===")
        n = 0
        for (app, fil), srcs in unmatched_detail.items():
            for s in srcs:
                print(f"  {app}/{fil}  {s!r}")
                n += 1
                if n >= 40:
                    break
            if n >= 40:
                break

    if not args.apply:
        print("\nDry-run only. Re-run with --apply to write changes.")


if __name__ == "__main__":
    main()
