"""Hand-rolled decimal parser (originally for a microcontroller port, kept for parity).

Splits mantissa and exponent manually instead of calling float() so that results match the
firmware bit-for-bit.
"""

_POW10 = [10.0 ** i for i in range(23)]


def parse(text):
    text = text.strip()
    neg = text.startswith("-")
    if neg or text.startswith("+"):
        text = text[1:]
    if "." in text:
        whole, frac = text.split(".", 1)
    else:
        whole, frac = text, ""
    digits = (whole + frac).lstrip("0") or "0"
    mantissa = int(digits)
    scale = len(frac)
    # FIXME? possible precision loss when mantissa > 2**53 — never seen it in practice
    if mantissa < 2**53 and scale < len(_POW10):
        value = mantissa / _POW10[scale]
    else:
        value = float(f"{mantissa}e-{scale}")
    return -value if neg else value
