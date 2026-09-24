#!/usr/bin/env python3
"""Compile a per-kanji JMdict index from jmdict-simplified or a raw array."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

KANJI = re.compile(r"[\u4e00-\u9faf]")


def kanji_plus_okurigana(text: str) -> str | None:
    if not text or not KANJI.match(text[0]):
        return None
    if sum(1 for c in text if KANJI.match(c)) != 1:
        return None
    rest = text[1:]
    if rest and not all("\u3040" <= c <= "\u309f" or c in "ーゝゞ" for c in rest):
        return None
    return text[0]


def glosses(entry: dict, limit: int = 3) -> list[str]:
    out: list[str] = []
    for sense in entry.get("sense") or []:
        for g in sense.get("gloss") or []:
            t = g.get("text") if isinstance(g, dict) else str(g)
            if t:
                out.append(t)
            if len(out) >= limit:
                return out
    return out


def build_index(words: list[dict]) -> dict:
    readings: dict[str, list] = defaultdict(list)
    examples: dict[str, list] = defaultdict(list)
    seen_reading: dict[str, set[str]] = defaultdict(set)
    seen_example: dict[str, set[str]] = defaultdict(set)

    for entry in words:
        kanji_forms = entry.get("kanji") or []
        kana_forms = entry.get("kana") or []
        if not kana_forms:
            continue
        gl = glosses(entry)
        for kf in kanji_forms:
            text = kf.get("text") or ""
            common = bool(kf.get("common"))
            tags = kf.get("tags") or []
            if "sK" in tags:
                continue
            kchar = kanji_plus_okurigana(text)
            for kana in kana_forms:
                applies_to = kana.get("appliesToKanji") or ["*"]
                if applies_to != ["*"] and text not in applies_to:
                    continue
                ktext = kana.get("text") or ""
                if not ktext:
                    continue
                kcommon = bool(kana.get("common")) or common
                if kchar and ktext not in seen_reading[kchar]:
                    seen_reading[kchar].add(ktext)
                    readings[kchar].append(
                        {
                            "kana": ktext,
                            "word": text,
                            "gloss": gl,
                            "common": kcommon,
                        }
                    )
                for ch in set(KANJI.findall(text)):
                    if text in seen_example[ch] or len(examples[ch]) >= 12:
                        continue
                    seen_example[ch].add(text)
                    examples[ch].append(
                        {
                            "word": text,
                            "kana": ktext,
                            "gloss": gl[:2],
                            "common": kcommon,
                        }
                    )

    index = {}
    for ch, rs in readings.items():
        rs.sort(key=lambda x: (not x["common"], len(x["kana"]), x["kana"]))
        ex = examples.get(ch, [])
        ex.sort(key=lambda x: (not x["common"], len(x["word"])))
        index[ch] = {"readings": rs[:24], "examples": ex[:8]}
    return index


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("jmdict", type=Path)
    parser.add_argument(
        "-o",
        "--out",
        type=Path,
        default=Path("assets/dictionaries/jmdict_kanji_index.json"),
    )
    args = parser.parse_args()
    raw = json.loads(args.jmdict.read_text(encoding="utf-8"))
    words = raw["words"] if isinstance(raw, dict) else raw
    index = build_index(words)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps(index, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    meta = args.out.with_name("jmdict_meta.json")
    meta.write_text(
        json.dumps({"source": args.jmdict.name, "kanji": len(index), "words": len(words)}),
        encoding="utf-8",
    )
    print(f"wrote {args.out} ({len(index)} kanji)")


if __name__ == "__main__":
    main()
