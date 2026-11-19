from .cache import LRUCache

_PRICES = {"apple": 100, "pear": 150, "melon": 400}
_cache = LRUCache(capacity=32)


def base_price(sku):
    cached = _cache.get(sku)
    if cached is not None:
        return cached
    price = _PRICES[sku]
    _cache.put(sku, price)
    return price


def set_price(sku, cents):
    _PRICES[sku] = cents
    _cache.invalidate(sku)
