import unittest
from duration import parse_duration


class T(unittest.TestCase):
    def test_basic(self):
        self.assertEqual(parse_duration("1h30m"), 5400)
        self.assertEqual(parse_duration("45s"), 45)
        self.assertEqual(parse_duration("2h"), 7200)

    def test_invalid(self):
        with self.assertRaises(ValueError):
            parse_duration("abc")


if __name__ == "__main__":
    unittest.main()
