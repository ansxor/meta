import unittest
import api, users

DB = {1: {"first": "Ada", "last": "L", "age": 36}}


class T(unittest.TestCase):
    def test_profile(self):
        self.assertEqual(api.profile(DB, 1), {"id": 1, "adult": True})

    def test_display(self):
        self.assertEqual(users.display_name(DB, 1), "Ada L")


if __name__ == "__main__":
    unittest.main()
