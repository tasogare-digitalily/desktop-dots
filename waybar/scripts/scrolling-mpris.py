import subprocess
import time
import json
import sys

# Customization settings
GLYPH_FONT_FAMILY = "Symbols Nerd Font Mono"
GLYPHS = {
    "paused": "",
    "playing": "",
    "stopped": ""
}
DEFAULT_GLYPH = ""
TEXT_WHEN_STOPPED = "Nothing playing right now"
SCROLL_TEXT_LENGTH = 20
REFRESH_INTERVAL = 0.3
PLAYERCTL_PATH = "/usr/bin/playerctl"

def get_player_info():
    """Fetches status, title, and artist in a single subprocess call."""
    try:
        # Queries playerctl for status, title, and artist separated by newlines
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

def marquee(text, width=SCROLL_TEXT_LENGTH):
    # Creates a seamless looping text string
    padded_text = text + "   "  # 3 spaces padding before loop repeats
    while True:
        for i in range(len(padded_text)):
            display_text = padded_text[i:] + padded_text[:i]
            yield display_text[:width].ljust(width)

if __name__ == "__main__":
    scroll_generator = None
    last_combined = ""

    while True:
        output = {}
        try:
            status, song, artist = get_player_info()
            
            if status != "stopped" and song and artist:
                combined = f"{song} -- {artist}"
            elif status != "stopped" and song:
                combined = song
            else:
                combined = ""

            # If the track changed, reset the marquee generator
            if combined != last_combined:
                scroll_generator = marquee(combined) if combined else None
                last_combined = combined

            # Determine text display based on status
            if status == "stopped" or not combined:
                scrolled_text = TEXT_WHEN_STOPPED.ljust(SCROLL_TEXT_LENGTH)
                scroll_generator = None
            elif status == "paused":
                scrolled_text = combined[:SCROLL_TEXT_LENGTH].ljust(SCROLL_TEXT_LENGTH)
            else:
                # Playing state logic
                if len(combined) > SCROLL_TEXT_LENGTH:
                    if scroll_generator:
                        scrolled_text = next(scroll_generator)
                    else:
                        scrolled_text = combined[:SCROLL_TEXT_LENGTH]
                else:
                    scrolled_text = combined.ljust(SCROLL_TEXT_LENGTH)

            glyph = GLYPHS.get(status, DEFAULT_GLYPH)
            output['text'] = f"<span font_family='{GLYPH_FONT_FAMILY}'>{glyph}</span>  {scrolled_text}"

        except Exception as e:
            output['text'] = f" Error: {str(e)}".ljust(SCROLL_TEXT_LENGTH + 2)

        print(json.dumps(output), flush=True)
        time.sleep(REFRESH_INTERVAL)