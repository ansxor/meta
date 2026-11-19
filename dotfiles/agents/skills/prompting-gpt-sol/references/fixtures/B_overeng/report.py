import json
import sys


def load_rows(path):
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def summarize(rows):
    by_region = {}
    for r in rows:
        by_region.setdefault(r["region"], 0)
        by_region[r["region"]] += r["amount"]
    return [{"region": k, "total": v} for k, v in sorted(by_region.items())]


def main(argv):
    rows = load_rows(argv[1])
    print(json.dumps(summarize(rows), indent=2))


if __name__ == "__main__":
    main(sys.argv)
