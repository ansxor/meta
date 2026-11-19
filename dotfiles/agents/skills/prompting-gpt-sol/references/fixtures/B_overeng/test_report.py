import unittest
import report


class T(unittest.TestCase):
    def test_summarize(self):
        rows = report.load_rows("sales.jsonl")
        self.assertEqual(report.summarize(rows), [{"region": "north", "total": 17}, {"region": "south", "total": 5}])


if __name__ == "__main__":
    unittest.main()
