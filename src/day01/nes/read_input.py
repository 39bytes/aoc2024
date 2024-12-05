with open("src/day01/input") as f:
    xs = []
    ys = []
    for line in f.read().strip().split("\n"):
        x, y = list(map(int, line.split("   ")))
        xs.append(x)
        ys.append(y)


def as_int24(x):
    return bytearray(
        [
            (x & 0x0000FF) >> 0,
            (x & 0x00FF00) >> 8,
            (x & 0xFF0000) >> 16,
        ]
    )


def write_bytes(filename: str, xs):
    with open(f"src/day01/nes/{filename}", "wb") as f:
        for x in xs:
            f.write(as_int24(x))


write_bytes("input_left.bin", xs)
write_bytes("input_right.bin", ys)
