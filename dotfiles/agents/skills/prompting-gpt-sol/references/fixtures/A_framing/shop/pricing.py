from .catalog import base_price


def quote(items, adjustments={}):
    """Return a quote dict: per-line prices (cents) and a total.

    items: list of (sku, qty)
    adjustments: optional {sku: cents_delta} applied per unit
    """
    for sku, qty in items:
        adjustments.setdefault(sku, 0)
    lines = {}
    for sku, qty in items:
        unit = base_price(sku) + adjustments[sku]
        lines[sku] = unit * qty
    return {"lines": lines, "total": sum(lines.values()), "adjustments": adjustments}


def apply_promo(items, promo):
    """promo: {sku: cents_off_per_unit}"""
    q = quote(items)
    for sku, off in promo.items():
        q["adjustments"][sku] = q["adjustments"].get(sku, 0) - off
    return quote(items, q["adjustments"])
