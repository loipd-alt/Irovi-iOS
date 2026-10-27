#!/usr/bin/env python3
"""Checks App Store field lengths in docs/ASO.md (Apple's limits)."""
import re

LIMITS = [("Name", 30), ("Subtitle", 30), ("Keywords", 100), ("Promotional Text", 170), ("Description", 4000)]

text = open("docs/ASO.md", encoding="utf-8").read()
for section in text.split("\n## ")[1:3]:  # English, Vietnamese
    title = section.splitlines()[0]
    print(title)
    for field, limit in LIMITS:
        match = re.search(r"\*\*" + re.escape(field) + r"\*\*[^\n]*\n```(?:text)?\n(.*?)\n```", section, re.S)
        if not match:
            continue
        value = match.group(1)
        status = "OK" if len(value) <= limit else "TOO LONG"
        print(f"  {field:17} {len(value):5}/{limit}  {status}")
