#!/usr/bin/env python3
"""Generates bundled Garake frame and sticker assets without external dependencies."""
import math
import os
import struct
import zlib


def write_png(path, width, height, pixel_fn):
    def chunk(chunk_type, data):
        body = chunk_type + data
        return (
            struct.pack('>I', len(data))
            + body
            + struct.pack('>I', zlib.crc32(body) & 0xFFFFFFFF)
        )

    rows = []
    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            row.extend(bytes(pixel_fn(x, y)))
        rows.append(bytes(row))

    raw = b''.join(rows)
    png = bytearray()
    png.extend(b'\x89PNG\r\n\x1a\n')
    png.extend(chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)))
    png.extend(chunk(b'IDAT', zlib.compress(raw, 9)))
    png.extend(chunk(b'IEND', b''))

    with open(path, 'wb') as file:
        file.write(png)


def point_in_poly(px, py, points):
    inside = False
    j = len(points) - 1
    for i, (xi, yi) in enumerate(points):
        xj, yj = points[j]
        if ((yi > py) != (yj > py)) and (
            px < (xj - xi) * (py - yi) / ((yj - yi) or 1e-9) + xi
        ):
            inside = not inside
        j = i
    return inside


def heart_pixel(x, y, size, rgb):
    cx = (x + 0.5) / size * 2 - 1
    cy = 1 - (y + 0.5) / size * 2
    cx *= 1.12
    cy *= 1.12
    value = (cx * cx + cy * cy - 0.67) ** 3 - cx * cx * cy ** 3
    if value <= 0:
        edge = min(1.0, abs(value) * 9)
        r = int(rgb[0] * (0.82 + 0.18 * edge))
        g = int(rgb[1] * (0.82 + 0.18 * edge))
        b = int(rgb[2] * (0.82 + 0.18 * edge))
        return (r, g, b, 255)
    return (0, 0, 0, 0)


def star_points(size=112, outer=0.45, inner=0.19):
    pts = []
    for i in range(10):
        ang = math.radians(-90 + i * 36)
        radius = outer if i % 2 == 0 else inner
        pts.append((size * (0.5 + math.cos(ang) * radius), size * (0.5 + math.sin(ang) * radius)))
    return pts


def star_pixel(x, y, points, rgb):
    if point_in_poly(x + 0.5, y + 0.5, points):
        glow = 0.9 + 0.1 * math.sin((x + y) * 0.3)
        return (int(rgb[0] * glow), int(rgb[1] * glow), int(rgb[2] * glow), 255)
    return (0, 0, 0, 0)


def sparkle_pixel(x, y, size, rgb):
    cx = x - size / 2
    cy = y - size / 2
    ax, ay = abs(cx), abs(cy)
    cross = (ax < size * 0.05 and ay < size * 0.31) or (ay < size * 0.05 and ax < size * 0.31)
    diag = abs(ax - ay) < size * 0.045 and ax < size * 0.28
    if cross or diag:
        lum = 0.86 + 0.14 * math.cos((x - y) * 0.24)
        return (int(rgb[0] * lum), int(rgb[1] * lum), int(rgb[2] * lum), 255)
    return (0, 0, 0, 0)


def in_rounded_rect(x, y, x0, y0, x1, y1, radius):
    if x < x0 or x > x1 or y < y0 or y > y1:
        return False
    r = radius
    if x0 + r <= x <= x1 - r or y0 + r <= y <= y1 - r:
        return True
    corners = [
        (x0 + r, y0 + r),
        (x1 - r, y0 + r),
        (x0 + r, y1 - r),
        (x1 - r, y1 - r),
    ]
    for cx, cy in corners:
        if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
            return True
    return False


def frame_pixel(x, y, width, height):
    outer = in_rounded_rect(x, y, 6, 6, width - 7, height - 7, 36)
    if not outer:
        return (0, 0, 0, 0)

    # Base metal body gradient.
    t = y / max(1, height - 1)
    r = int(236 - 36 * t)
    g = int(239 - 34 * t)
    b = int(247 - 43 * t)

    # Side shadowing.
    edge = min(x, width - 1 - x, y, height - 1 - y)
    shade = max(0.72, min(1.0, edge / 18))
    r, g, b = int(r * shade), int(g * shade), int(b * shade)

    # Display bezel.
    sx0, sx1 = int(width * 0.09), int(width * 0.91)
    sy0, sy1 = int(height * 0.055), int(height * 0.635)
    bezel_outer = in_rounded_rect(x, y, sx0, sy0, sx1, sy1, 14)
    bezel_inner = in_rounded_rect(x, y, sx0 + 13, sy0 + 13, sx1 - 13, sy1 - 13, 6)
    if bezel_outer and not bezel_inner:
        return (28, 31, 39, 255)
    if bezel_inner:
        # Transparent center where preview is shown.
        return (0, 0, 0, 0)

    # Keypad plate region.
    py0 = int(height * 0.67)
    if y > py0:
        pt = (y - py0) / max(1, (height - py0))
        r, g, b = int(245 - 26 * pt), int(246 - 24 * pt), int(250 - 28 * pt)

    # Decorative top signal slit.
    if int(height * 0.028) <= y <= int(height * 0.036) and int(width * 0.39) <= x <= int(width * 0.61):
        return (168, 173, 185, 255)

    # Fine noise grain for realism.
    grain = ((x * 17 + y * 13) % 9) - 4
    r = max(0, min(255, r + grain))
    g = max(0, min(255, g + grain))
    b = max(0, min(255, b + grain))

    return (r, g, b, 255)


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, '..'))
    stickers_dir = os.path.join(project_root, 'assets', 'stickers')
    frame_dir = os.path.join(project_root, 'assets', 'frame')

    os.makedirs(stickers_dir, exist_ok=True)
    os.makedirs(frame_dir, exist_ok=True)

    size = 112
    write_png(os.path.join(stickers_dir, 'heart_red.png'), size, size, lambda x, y: heart_pixel(x, y, size, (245, 52, 74)))
    write_png(os.path.join(stickers_dir, 'heart_pink.png'), size, size, lambda x, y: heart_pixel(x, y, size, (248, 132, 186)))

    points = star_points(size=size)
    write_png(os.path.join(stickers_dir, 'star_yellow.png'), size, size, lambda x, y: star_pixel(x, y, points, (251, 226, 84)))
    write_png(os.path.join(stickers_dir, 'star_orange.png'), size, size, lambda x, y: star_pixel(x, y, points, (255, 193, 98)))

    write_png(os.path.join(stickers_dir, 'sparkle_gold.png'), size, size, lambda x, y: sparkle_pixel(x, y, size, (255, 241, 132)))
    write_png(os.path.join(stickers_dir, 'sparkle_pink.png'), size, size, lambda x, y: sparkle_pixel(x, y, size, (251, 164, 216)))

    width, height = 960, 1706
    write_png(os.path.join(frame_dir, 'phone_shell.png'), width, height, lambda x, y: frame_pixel(x, y, width, height))


if __name__ == '__main__':
    main()
