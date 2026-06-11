#!/usr/bin/env python3
import subprocess
import time
import json
import unicodedata
import html  # <-- Added to safely escape ampersands for Pango markup

# Customization settings
GLYPH_FONT_FAMILY = "Symbols Nerd Font Mono"
GLYPHS = {
    "paused": "",
    "playing": "",
    "stopped": ""
}
DEFAULT_GLYPH = ""
TEXT_WHEN_STOPPED = "Nothing playing"
SCROLL_TEXT_LENGTH = 25  # Snug threshold: anything longer scrolls at 15 wide
REFRESH_INTERVAL = 0.4
PLAYERCTL_PATH = "/usr/bin/playerctl"

def get_visual_width(text):
    """Calculates visual width taking Full-width CJK characters into account."""
    width = 0
    for char in text:
        if unicodedata.east_asian_width(char) in ('W', 'F', 'A'):
            width += 2
        else:
            width += 1
    return width

def visual_slice(text, max_width):
    """Slices text up to a strict visual width and pads it perfectly if scrolling."""
    res = ""
    current_width = 0
    for char in text:
        char_width = 2 if unicodedata.east_asian_width(char) in ('W', 'F', 'A') else 1
        if current_width + char_width > max_width:
            break
        res += char
        current_width += char_width
    return res + " " * (max_width - current_width)

def get_player_info():
    try:
        result = subprocess.run(
            [PLAYERCTL_PATH, 'metadata', '--format', '{{status}}\n{{title}}\n{{artist}}'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        if result.returncode != 0 or not result.stdout.strip():
            return "stopped", "", ""
        
        lines = result.stdout.strip().split('\n')
        status = lines[0].lower() if len(lines) > 0 else "stopped"
        title = lines[1] if len(lines) > 1 else ""
        artist = lines[2] if len(lines) > 2 else ""
        
        return status, title, artist
    except Exception:
        return "stopped", "", ""

if __name__ == "__main__":
    last_combined = ""
    scroll_index = 0

    while True:
        output = {}
        try:
            status, song, artist = get_player_info()
            
            if status != "stopped" and song and artist:
                combined = f"{song} - {artist}"
            elif status != "stopped" and song:
                combined = song
            else:
                combined = ""

            if combined != last_combined:
                scroll_index = 0
                last_combined = combined

            # Calculate total visual width of the song info
            song_width = get_visual_width(combined)

            # Determine scroll text based on track properties
            if status == "stopped" or not combined:
                scrolled_text = TEXT_WHEN_STOPPED
            elif status == "paused":
                if song_width > SCROLL_TEXT_LENGTH:
                    scrolled_text = visual_slice(combined, SCROLL_TEXT_LENGTH)
                else:
                    scrolled_text = combined
            else:
                # Playing state scrolling logic
                if song_width > SCROLL_TEXT_LENGTH:
                    padded_text = combined + "   "
                    text_len = len(padded_text)
                    start = scroll_index % text_len
                    
                    double_text = padded_text + padded_text
                    scrolled_text = visual_slice(double_text[start:], SCROLL_TEXT_LENGTH)
                    scroll_index += 1
                else:
                    scrolled_text = combined

            glyph = GLYPHS.get(status, DEFAULT_GLYPH)
            
            # Escape special XML/HTML characters (like &) so Pango markup doesn't choke
            safe_text = html.escape(scrolled_text)
            
            # Enforce the 12px monospaced grid via Pango
            font_stack = "Noto Sans Mono CJK JP, Noto Sans CJK JP Mono, Symbols Nerd Font Mono"
            output['text'] = f"<span font_desc='{font_stack}' size='200%'>{glyph}  {safe_text}</span>"
            output['class'] = status

        except Exception as e:
            output['text'] = " Error"
            output['class'] = "stopped"

        print(json.dumps(output), flush=True)
        time.sleep(REFRESH_INTERVAL)