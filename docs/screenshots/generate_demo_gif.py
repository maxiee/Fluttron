#!/usr/bin/env python3
"""Generate a terminal-style demo GIF for Fluttron CLI.

Usage: python3 generate_demo_gif.py
Output: demo.gif in the same directory as this script
"""

import os
from PIL import Image, ImageDraw, ImageFont

# --- Configuration ---
WIDTH = 820
FONT_SIZE = 15
LINE_HEIGHT = 23
PADDING_X = 28
PADDING_Y = 22

# TokyoNight color theme
BG_COLOR = (26, 27, 38)         # #1a1b26 - background
TEXT_COLOR = (169, 177, 214)    # #a9b1d6 - default text
PROMPT_COLOR = (122, 162, 247)  # #7aa2f7 - $ prompt (blue)
CMD_COLOR = (224, 175, 104)     # #e0af68 - command (yellow/orange)
SUCCESS_COLOR = (158, 206, 106) # #9ece6a - success (green)
DIM_COLOR = (86, 95, 137)       # #565f89 - dimmed text
CYAN_COLOR = (125, 207, 255)    # #7dcfff - cyan accent
CURSOR_COLOR = (192, 202, 245)  # #c0caf5 - cursor

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def load_font(size):
    """Try to load a monospace font, fall back to default."""
    font_paths = [
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Monaco.dfont",
        "/Library/Fonts/Courier New.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    print("Warning: Using default bitmap font (may look pixelated)")
    return ImageFont.load_default()


FONT = load_font(FONT_SIZE)


def text_width(draw, text):
    """Get the pixel width of text."""
    if not text:
        return 0
    bbox = draw.textbbox((0, 0), text, font=FONT)
    return bbox[2] - bbox[0]


# --- Frame definitions ---
# Each frame is a list of line tuples: (color, text_segment_list)
# text_segment_list: [(color, text), ...]
# cursor_at_end: bool
# duration_ms: int

def make_prompt_line(cmd_text, typed_chars=None):
    """Create a prompt line with optional partial typing."""
    parts = [(PROMPT_COLOR, "❯ ")]
    if typed_chars is not None:
        parts.append((CMD_COLOR, cmd_text[:typed_chars]))
    else:
        parts.append((CMD_COLOR, cmd_text))
    return parts


def make_output_line(text, color=TEXT_COLOR):
    return [(color, text)]


def make_blank():
    return [(TEXT_COLOR, "")]


# Define the full animation sequence
FRAMES = []

def add_frame(lines, duration, cursor=True):
    FRAMES.append({
        "lines": lines,
        "duration": duration,
        "cursor": cursor,
    })


def build_animation():
    # ── Frame 0: Initial prompt ──
    add_frame([make_prompt_line("")], 700)

    # ── "fluttron --version" ──
    cmd1 = "fluttron --version"
    # Type the command
    for i in range(1, len(cmd1) + 1, 3):
        add_frame([make_prompt_line(cmd1, i)], 55)
    add_frame([make_prompt_line(cmd1)], 300)

    # Show output
    lines_v = [
        make_prompt_line(cmd1),
        make_blank(),
        make_output_line("  0.1.0-dev", CYAN_COLOR),
        make_blank(),
    ]
    add_frame(lines_v, 900, cursor=False)

    # ── "fluttron doctor" ──
    cmd2 = "fluttron doctor"
    base = [
        make_prompt_line(cmd1),
        make_blank(),
        make_output_line("  0.1.0-dev", CYAN_COLOR),
        make_blank(),
    ]
    for i in range(1, len(cmd2) + 1, 3):
        add_frame(base + [make_prompt_line(cmd2, i)], 55)
    add_frame(base + [make_prompt_line(cmd2)], 300)

    # Show doctor output lines one by one
    doctor_lines = [
        ("Checking Flutter SDK ...........  ", None, "✓ Flutter 3.29.0 (stable)"),
        ("Checking Dart SDK ..............  ", None, "✓ Dart 3.7.0"),
        ("Checking Node.js ...............  ", None, "✓ Node v22.13.1"),
        ("Checking pnpm ..................  ", None, "✓ pnpm 9.15.4"),
        ("Checking macOS desktop .........  ", None, "✓ macOS desktop enabled"),
    ]

    accumulated_doctor = list(base) + [make_prompt_line(cmd2), make_blank()]
    for prefix, _, suffix in doctor_lines:
        line_parts = [(DIM_COLOR, "  " + prefix), (SUCCESS_COLOR, suffix)]
        accumulated_doctor.append(line_parts)
        add_frame(list(accumulated_doctor), 220, cursor=False)

    accumulated_doctor.append(make_blank())
    accumulated_doctor.append([(SUCCESS_COLOR, "  ✓ All checks passed!")])
    add_frame(list(accumulated_doctor), 1200, cursor=False)

    # ── "fluttron create ./hello_app --name HelloApp" ──
    cmd3 = "fluttron create ./hello_app --name HelloApp"

    # Build accumulated display (show doctor summary condensed)
    base2 = [
        make_prompt_line(cmd1),
        make_output_line("  0.1.0-dev", CYAN_COLOR),
        make_blank(),
        make_prompt_line(cmd2),
        make_output_line("  ✓ Flutter 3.29.0  ✓ Dart 3.7.0  ✓ Node v22  ✓ pnpm 9  ✓ macOS", SUCCESS_COLOR),
        make_output_line("  ✓ All checks passed!", SUCCESS_COLOR),
        make_blank(),
    ]

    for i in range(1, len(cmd3) + 1, 4):
        add_frame(base2 + [make_prompt_line(cmd3, i)], 50)
    add_frame(base2 + [make_prompt_line(cmd3)], 300)

    create_output = [
        make_output_line("  Creating Fluttron app: HelloApp", DIM_COLOR),
        make_output_line("  Scaffolding host + ui + shared packages ...", DIM_COLOR),
        [(SUCCESS_COLOR, "  ✓ Created ./hello_app")],
    ]
    add_frame(base2 + [make_prompt_line(cmd3)] + create_output, 900, cursor=False)

    # ── "fluttron build -p ./hello_app" ──
    cmd4 = "fluttron build -p ./hello_app"
    base3 = base2 + [
        make_prompt_line(cmd3),
        [(SUCCESS_COLOR, "  ✓ Created ./hello_app")],
        make_blank(),
    ]

    for i in range(1, len(cmd4) + 1, 4):
        add_frame(base3 + [make_prompt_line(cmd4, i)], 50)
    add_frame(base3 + [make_prompt_line(cmd4)], 300)

    build_output_steps = [
        (DIM_COLOR, "  Running pnpm install ..."),
        (DIM_COLOR, "  Running flutter build web ..."),
        (DIM_COLOR, "  Discovering web packages ..."),
        (DIM_COLOR, "  Collecting assets ..."),
        (SUCCESS_COLOR, "  ✓ Build complete  →  ./hello_app/host/assets/www/"),
    ]
    accumulated_build = base3 + [make_prompt_line(cmd4)]
    for color, text in build_output_steps:
        accumulated_build.append([(color, text)])
        add_frame(list(accumulated_build), 350, cursor=False)

    # ── "fluttron run -p ./hello_app" ──
    cmd5 = "fluttron run -p ./hello_app"
    base4 = base3 + [
        make_prompt_line(cmd4),
        make_output_line("  ✓ Build complete  →  ./hello_app/host/assets/www/", SUCCESS_COLOR),
        make_blank(),
    ]

    for i in range(1, len(cmd5) + 1, 4):
        add_frame(base4 + [make_prompt_line(cmd5, i)], 55)
    add_frame(base4 + [make_prompt_line(cmd5)], 300)

    run_output = [
        [(DIM_COLOR, "  Launching Flutter Desktop (macOS) ...")],
        [(SUCCESS_COLOR, "  ✓ HelloApp is running!")],
        [make_blank()[0]],
    ]
    for step in run_output:
        base4 = base4 + [make_prompt_line(cmd5)] if step == run_output[0] else base4
        add_frame(
            base4 + run_output[:run_output.index(step) + 1],
            600 if step != run_output[-1] else 2000,
            cursor=(step == run_output[-1]),
        )

    # Final frame: new prompt waiting
    final = base4 + [
        make_prompt_line(cmd5),
        make_output_line("  ✓ HelloApp is running!", SUCCESS_COLOR),
        make_blank(),
        make_prompt_line(""),
    ]
    add_frame(final, 2000, cursor=True)


build_animation()


def calculate_canvas_height(frames):
    """Calculate the fixed height needed to display all frames."""
    max_lines = max(len(f["lines"]) for f in frames)
    return PADDING_Y * 2 + max_lines * LINE_HEIGHT


def render_frame(draw_img, lines, show_cursor):
    """Render a single frame onto the given image (in-place)."""
    draw = ImageDraw.Draw(draw_img)
    # Fill background
    draw.rectangle([0, 0, draw_img.width, draw_img.height], fill=BG_COLOR)

    # Draw window chrome (title bar)
    chrome_height = 28
    draw.rectangle([0, 0, draw_img.width, chrome_height], fill=(36, 37, 50))
    # Traffic light buttons
    for i, color in enumerate([(255, 95, 87), (255, 189, 46), (40, 200, 64)]):
        cx = 16 + i * 20
        cy = chrome_height // 2
        draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=color)
    # Title
    title = "Terminal — fluttron demo"
    title_bbox = draw.textbbox((0, 0), title, font=FONT)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((draw_img.width - title_w) // 2, 6), title, font=FONT, fill=DIM_COLOR)

    y = PADDING_Y + chrome_height
    cursor_x = None
    cursor_y = None

    for line_idx, line_parts in enumerate(lines):
        x = PADDING_X
        for color, segment in line_parts:
            if segment:
                draw.text((x, y), segment, font=FONT, fill=color)
                seg_bbox = draw.textbbox((x, y), segment, font=FONT)
                x = seg_bbox[2]
        if line_idx == len(lines) - 1:
            cursor_x = x
            cursor_y = y
        y += LINE_HEIGHT

    # Draw cursor on last line
    if show_cursor and cursor_x is not None:
        draw.rectangle(
            [cursor_x + 2, cursor_y, cursor_x + 2 + 8, cursor_y + LINE_HEIGHT - 3],
            fill=CURSOR_COLOR
        )


def generate_gif():
    output_path = os.path.join(SCRIPT_DIR, "demo.gif")
    print(f"Generating demo GIF: {output_path}")
    print(f"Total frames: {len(FRAMES)}")

    canvas_height = calculate_canvas_height(FRAMES) + 28  # +28 for chrome
    print(f"Canvas: {WIDTH}x{canvas_height}")

    images = []
    durations = []

    for i, frame in enumerate(FRAMES):
        img = Image.new("RGB", (WIDTH, canvas_height), BG_COLOR)
        render_frame(img, frame["lines"], frame["cursor"])
        images.append(img)
        durations.append(frame["duration"])

    if not images:
        print("No frames generated!")
        return

    # Quantize to 256 colors for GIF
    print("Quantizing frames ...")
    palette_images = []
    for img in images:
        p = img.quantize(colors=64, dither=Image.Dither.NONE)
        palette_images.append(p)

    print("Saving GIF ...")
    palette_images[0].save(
        output_path,
        save_all=True,
        append_images=palette_images[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Done! {len(images)} frames, {size_mb:.2f} MB → {output_path}")
    if size_mb > 2:
        print(f"WARNING: File size {size_mb:.2f}MB exceeds 2MB limit!")


if __name__ == "__main__":
    generate_gif()
