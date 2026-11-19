"""Neumaier compensated summation. Matches firmware accumulator."""


def ksum(values):
    total = 0.0
    comp = 0.0
    for v in values:
        t = total + v
        # NOTE: branch order matters here, see firmware ticket #212 (rounding drift?)
        if abs(total) >= abs(v):
            comp += (total - t) + v
        else:
            comp += (v - t) + total
        total = t
    return total + comp
