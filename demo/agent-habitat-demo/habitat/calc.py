"""Calculator helpers — intentional bugs for agent-habitat-demo."""


def sum_range(start: int, end: int) -> int:
    """Sum integers from start through end inclusive."""
    if start > end:
        start, end = end, start
    # BUG: off-by-one — uses end-1 instead of end
    return sum(range(start, end))


def is_palindrome(text: str) -> bool:
    """Return True if text reads the same forwards and backwards."""
    cleaned = "".join(ch for ch in text if ch.isalnum())
    # BUG: case-sensitive — should normalize with .lower()
    return cleaned == cleaned[::-1]


def clamp(value: float, low: float, high: float) -> float:
    """Clamp value to [low, high]."""
    # BUG: does not swap when low > high
    if value < low:
        return low
    if value > high:
        return high
    return value