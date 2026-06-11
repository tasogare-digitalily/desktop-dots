import subprocess
import time
import json
import html
import unicodedata  # CRITICAL: Used to measure true visual character widths

GLYPHS = {"paused": "", "playing": "", "stopped": ""}
DEFAULT_GLYPH = ""
TEXT_WHEN_STOPPED = "Nothing playing right now"

SCROLL_TEXT_LENGTH = 20  
REFRESH_INTERVAL = 0.35  
PLAYERCTL_PATH = "/usr/bin/playerctl"

def get_visual_width(text):
    """Calculates the true visual column width of a string (East Asian characters = 2)."""
    width = 0
    for char in text:
        # 'W' (Wide) and 'F' (Fullwidth) characters take up 2 columns in terminal fonts
        if unicodedata.east_asian_width(char) in ('W', 'F'):
            width += 2
        else:
            width += 1
    return width

def get_player_info():
    try:
        result = subprocess.run(
            [PLAYERCTL_PATH, 'metadata', '--format', '{{status}}\n{{title}}\n{{artist}}'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=0.15
        )
        if result.returncode != 0 or not result.stdout.strip():
            return "stopped", "", ""
        
        lines = result.stdout.strip().split('\n')
        return (lines[0].lower() if len(lines) > 0 else "stopped",
                lines[1] if len(lines) > 1 else "",
                lines[2] if len(lines) > 2 else "")
    except Exception:
        return "stopped", "", ""

def marquee_visual(text, max_width=SCROLL_TEXT_LENGTH):
    """Generates continuous steps, strictly handling mixed-scripts and pausing at the start."""
    # Add trailing spaces so the end of the text doesn't slam into the beginning
    padded_text = text + "     "
    
    # Configuration for the rest period:
    # 0.35s refresh interval * 6 ticks = ~2.1 seconds of resting at the start
    REST_TICKS = 6 
    
    while True:
        for i in range(len(padded_text)):
            
            # --- START RESET PAUSE LOGIC ---
            if i == 0:
                # Calculate the exact initial frame layout
                initial_chunk = ""
                initial_width = 0
                for char in padded_text:
                    char_w = 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1
                    if initial_width + char_w > max_width:
                        break
                    initial_chunk += char
                    initial_width += char_w
                
                initial_remainder = max_width - initial_width
                initial_frame = initial_chunk + (" " * initial_remainder)
                
                # Yield the exact same starting frame multiple times to create a visual "rest"
                for _ in range(REST_TICKS):
                    yield initial_frame
            # --- END RESET PAUSE LOGIC ---

            # Continue with normal rotation for every step after index 0
            rotated = padded_text[i:] + padded_text[:i]
            
            current_chunk = ""
            current_width = 0
            
            for char in rotated:
                char_w = 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1
                if current_width + char_w > max_width:
                    break
                current_chunk += char
                current_width += char_w
            
            remainder = max_width - current_width
            yield current_chunk + (" " * remainder)
            
            if __name__ == "__main__":
    scroll_generator = None
    last_combined = ""

    while True:
        output = {}
        try:
            status, song, artist = get_player_info()
            combined = f"{song} -- {artist}" if (status != "stopped" and song and artist) else (song if (status != "stopped" and song) else "")

            # Reset generator if the track shifts
            if combined != last_combined:
                scroll_generator = marquee_visual(combined) if combined else None
                last_combined = combined

            # Determine frame text
            if status == "stopped" or not combined:
                scrolled_text = TEXT_WHEN_STOPPED
                scroll_generator = None
            elif status == "paused":
                # Only slice if it actually exceeds the maximum width
                if get_visual_width(combined) > SCROLL_TEXT_LENGTH:
                    scrolled_text = ""
                    w = 0
                    for c in combined:
                        cw = 2 if unicodedata.east_asian_width(c) in ('W', 'F') else 1
                        if w + cw > SCROLL_TEXT_LENGTH: break
                        scrolled_text += c
                        w += cw
                else:
                    scrolled_text = combined
            else:
                # If the track is long, let the marquee handle the step and padding
                if get_visual_width(combined) > SCROLL_TEXT_LENGTH and scroll_generator:
                    scrolled_text = next(scroll_generator)
                else:
                    # REMOVED .ljust() -> Short songs pass through naturally without forced spaces
                    scrolled_text = combined

            escaped_text = html.escape(scrolled_text)
            glyph = GLYPHS.get(status, DEFAULT_GLYPH)
            output['text'] = f"{glyph}  {escaped_text}"

        except Exception:
            output['text'] = " Stopped"

        print(json.dumps(output), flush=True)
        time.sleep(REFRESH_INTERVAL)