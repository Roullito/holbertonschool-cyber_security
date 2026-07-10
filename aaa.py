import hashlib
import secrets
import re
from pathlib import Path


FLAG_PATTERN = re.compile(r"^[0-9a-f]{32}$")


def random_flag() -> str:
    """Génère une valeur aléatoire de 128 bits, encodée sur 32 caractères hexadécimaux."""
    return secrets.token_hex(16)


def md5_flag(value: str) -> str:
    """Génère le hash MD5 d'une chaîne."""
    return hashlib.md5(value.encode("utf-8")).hexdigest()


def is_valid_format(flag: str) -> bool:
    """Vérifie uniquement le format observé dans les exemples."""
    return bool(FLAG_PATTERN.fullmatch(flag.strip().lower()))


def generate_candidates(count: int, words: list[str]) -> list[str]:
    candidates = set()

    # Valeurs totalement aléatoires
    for _ in range(count):
        candidates.add(random_flag())

    # MD5 de mots ou chaînes candidates
    for word in words:
        word = word.strip()

        if not word:
            continue

        variants = {
            word,
            word.lower(),
            word.upper(),
            word.capitalize(),
            f"flag{{{word}}}",
            f"FLAG{{{word}}}",
            f"{word}123",
            f"{word}2026",
        }

        for variant in variants:
            candidates.add(md5_flag(variant))

    return sorted(candidates)


def main() -> None:
    words = [
        "admin",
        "password",
        "root",
        "secret",
        "flag",
        "ctf",
        "challenge",
    ]

    candidates = generate_candidates(
        count=20,
        words=words,
    )

    output_file = Path("flag_candidates.txt")
    output_file.write_text("\n".join(candidates) + "\n", encoding="utf-8")

    print(f"{len(candidates)} candidats générés dans {output_file}")
    print()

    for candidate in candidates[:10]:
        print(candidate)


if __name__ == "__main__":
    main()
