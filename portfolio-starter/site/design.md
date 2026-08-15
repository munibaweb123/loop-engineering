# The design decision

The page is the overnight shift: it opens in the deep ink-blue night Muniba actually works (9 AM – 5 PM PST from Karachi, fully remote) and hands the reader over a sunrise seam into the warm daylight of the clients she is built to serve — because everything she ships is full-stack work done in the hours that connect Pakistan to someone's day.

## Why this person

The CV's first lines are a time-zone fact, not a decoration: "Available for 9:00 AM – 5:00 PM PST (overnight shift, Pakistan) · Fully remote." Nobody else in the room works the night so that a client's morning works. The page is built on that one fact: night is the page's default, the seam is the moment her workday hands off, and daylight is the client's reward below it. A light-template-with-a-portrait would be true of any developer; a page that is structurally a night shift is only Muniba's.

## How the page carries it out

- The hero is night: a full-viewport ink-blue field, her name in the page's largest clamp()ed type, the nav embedded in the night.
- The seam is the horizon: the dark hero ends where the warm daylight content begins, and the accent is the sun that sits on that line — used only for the seam itself, the focus ring, active nav states, and key words. One meaning: the sun.
- Below the seam, the body is warm daylight: about, a project card grid (a set of things that looks like a set), skills as a chip field, contact.
- One structural interaction the page owns: the nav tracks where you are (scrollspy), cards answer to hover, and content reveals as it crosses the seam into the day. At 390px the hero stays full-viewport, the seam still reads, and type clamps rather than shrinking linearly.

## Tokens

:root {
  /* night (hero, default) — checked pair */
  --bg: #0e1626;  --fg: #eaf0f8;  --accent: #f0a02c;
  /* day (below the seam) */
  --bg-day: #f7f4ec; --fg-day: #1c2430; --accent-day: #8a4a00;

  --text-xs: 0.8rem;  --text-sm: 0.9rem;  --text-base: 1.05rem;
  --text-lg: 1.4rem;  --text-xl: 2.1rem;
  --text-2xl: clamp(3.2rem, 11vw, 8.5rem);

  --space-1: 0.3rem; --space-2: 0.6rem; --space-3: 1.1rem;
  --space-4: 2rem;   --space-5: 3.5rem; --space-6: 7rem;

  --measure: 47ch;
}
