"""Merge overlapping (and touching) intervals."""


def merge_intervals(intervals):
    """Merge a list of (start, end) intervals.

    Two intervals merge if they overlap OR touch — e.g. (1, 3) and (3, 5)
    merge into (1, 5), because there is no gap between them.

    Returns a new list, sorted by start, holding the smallest possible
    number of non-overlapping, non-touching intervals.
    """
    if not intervals:
        return []

    ordered = sorted(intervals, key=lambda iv: iv[0])
    merged = [list(ordered[0])]

    for start, end in ordered[1:]:
        last = merged[-1]
        if start < last[1]:
            last[1] = max(last[1], end)
        else:
            merged.append([start, end])

    return [tuple(iv) for iv in merged]
