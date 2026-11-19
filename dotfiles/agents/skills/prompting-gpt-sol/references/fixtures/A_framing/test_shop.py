import unittest

from shop import catalog, pricing


class ShopTests(unittest.TestCase):
    def test_promo_then_regular_quote(self):
        promo = pricing.apply_promo([("apple", 2)], {"apple": 20})
        self.assertEqual(promo["total"], 160)
        regular = pricing.quote([("apple", 2)])
        self.assertEqual(regular["total"], 200)  # fails: stale promo price shows up

    def test_set_price_reflected(self):
        catalog.set_price("pear", 175)
        self.assertEqual(pricing.quote([("pear", 1)])["total"], 175)
        catalog.set_price("pear", 150)

    def test_multi_line(self):
        q = pricing.quote([("apple", 1), ("melon", 2)])
        self.assertEqual(q["total"], 900)


if __name__ == "__main__":
    unittest.main()
