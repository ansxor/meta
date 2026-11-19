import re

_UNITS = {"h": 3600, "m": 60, "s": 1}


def parse_duration(text):
    """Parse strings like '1h30m', '45s', '2h' into seconds.

    Raises ValueError on invalid input.
    """
    parts = re.findall(r"(\d+)([hms])", text)
    if not parts:
        raise ValueError(f"invalid duration: {text!r}")
    return sum(int(n) * _UNITS[u] for n, u in parts)
