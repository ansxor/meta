import configparser
import csv
import sys

from numlib.fastfloat import parse
from numlib.ksum import ksum


def load(cfg):
    inp = cfg["input"]
    with open(inp["path"], newline="") as f:
        lines = f.read().splitlines()
    body = lines[inp.getint("header_rows"):]
    col = inp.getint("column")
    return [parse(row[col]) for row in csv.reader(body) if row]


def main(cfg_path="stats.ini"):
    cfg = configparser.ConfigParser()
    cfg.read(cfg_path)
    values = load(cfg)
    mean = ksum(values) / len(values)
    print(f"mean = {mean:.{cfg['output'].getint('precision')}f}")


if __name__ == "__main__":
    main(*sys.argv[1:])
