#!/usr/bin/env python3
import subprocess
import time
import json
import unicodedata
import html

# Customization settings
GLYPH_FONT_FAMILY = "Symbols Nerd Font Mono"
GLYPHS = {
    "paused": "",
    "playing": "",
    "stopped": ""
}
DEFAULT_GLYPH = ""
TEXT_WHEN_STOPPED = "Nothing playing"
SCROLL_TEXT_LENGTH = 25  
REFRESH_INTERVAL = 0.4
PLAYERCTL_PATH = "/usr/bin/playerctl"

# 5 frames * 0.4s refresh interval = 2.0 second pause
PAUSE_FRAMES = 5 

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
    pause_counter = 0  # Frame counter to handle the pause at the beginning

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

            # If the song changes, reset index and start with a fresh pause
            if combined != last_combined:
                scroll_index = 0
                pause_counter = PAUSE_FRAMES
                last_combined = combined

            song_width = get_visual_width(combined)

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
                    
                    # Handle pausing/scrolling index increments
                    if pause_counter > 0:
                        pause_counter -= 1  # Stay on current frame, count down pause
                    else:
                        scroll_index += 1
                        # If the next frame loops back to the very beginning, trigger a pause
                        if (scroll_index % text_len) == 0:
                            pause_counter = PAUSE_FRAMES
                else:
                    scrolled_text = combined

            glyph = GLYPHS.get(status, DEFAULT_GLYPH)
            safe_text = html.escape(scrolled_text)
            
            font_stack = "Noto Sans Mono CJK JP, Noto Sans CJK JP Mono, Symbols Nerd Font Mono"
            output['text'] = f"<span font_desc='{font_stack}' size='200%'>{glyph}  {safe_text}</span>"
            output['class'] = status

        except Exception as e:
            output['text'] = " Error"
            output['class'] = "stopped"

        print(json.dumps(output), flush=True)
        time.sleep(REFRESH_INTERVAL)