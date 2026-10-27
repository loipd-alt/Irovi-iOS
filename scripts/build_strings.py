#!/usr/bin/env python3
"""Builds Irovi/Resources/Localizable.xcstrings from the code and translations.

Usage (from the repo root, after a build so the .stringsdata files exist):
    python3 scripts/build_strings.py

- Source keys: every string the compiler extracted from the Swift code (English).
- Translations: scripts/strings/<code>.json, one file per language ({english: translated}).
- Fails if a language is missing a key or a translation drops/changes a
  placeholder (%lld, %@), so nothing ships untranslated or broken.
- Also writes scripts/strings/_source_en.json, the list to give translators.
Article bodies live in Irovi/Resources/Articles/articles.<code>.json.
"""
import glob
import json
import re
import sys

LANGUAGES = ["vi", "es", "pt-BR", "fr", "de", "ja", "id"]
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|f|\.\d+f)")


def extracted_keys():
    """Keys from the newest .stringsdata of each Swift source file, so strings
    removed from the code don't linger from older build folders."""
    import os
    newest = {}
    for path in glob.glob("build/**/Irovi.build/**/*.stringsdata", recursive=True):
        if "Tests" in path:
            continue
        with open(path) as f:
            data = json.load(f)
        source = data.get("source", path)
        mtime = os.path.getmtime(path)
        if source not in newest or mtime > newest[source][0]:
            newest[source] = (mtime, data)
    keys = set()
    for _, data in newest.values():
        for entry in data.get("tables", {}).get("Localizable", []):
            keys.add(entry["key"])
    return keys


def placeholders(text):
    return sorted(re.sub(r"\d+\$", "", p) for p in PLACEHOLDER.findall(text))


def main():
    keys = extracted_keys()
    if not keys:
        sys.exit("No .stringsdata found — build the app first.")
    with open("scripts/strings/_source_en.json", "w", encoding="utf-8") as f:
        json.dump(sorted(keys), f, ensure_ascii=False, indent=2)

    problems = []
    tables = {}
    for code in LANGUAGES:
        try:
            with open(f"scripts/strings/{code}.json", encoding="utf-8") as f:
                table = json.load(f)
        except FileNotFoundError:
            problems.append(f"{code}: scripts/strings/{code}.json is missing")
            continue
        for key in sorted(keys):
            if key not in table or not str(table[key]).strip():
                problems.append(f"{code}: missing {key!r}")
            elif placeholders(key) != placeholders(table[key]):
                problems.append(f"{code}: placeholders differ in {key!r} -> {table[key]!r}")
        tables[code] = table
    if problems:
        print("\n".join(problems))
        sys.exit(1)

    catalog = {
        "sourceLanguage": "en",
        "strings": {
            key: {"localizations": {
                # "en" is written out too, so an en.lproj exists for the in-app English choice.
                "en": {"stringUnit": {"state": "translated", "value": key}},
                **{code: {"stringUnit": {"state": "translated", "value": tables[code][key]}} for code in LANGUAGES},
            }}
            for key in sorted(keys)
        },
        "version": "1.0",
    }
    with open("Irovi/Resources/Localizable.xcstrings", "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
    print(f"{len(keys)} strings × {len(LANGUAGES) + 1} languages written.")


if __name__ == "__main__":
    main()
