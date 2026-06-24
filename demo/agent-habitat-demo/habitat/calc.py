"""Calculator helpers — agent-habitat-demo."""


def sum_range(start: int, end: int) -> int:
    """Sum integers from start through end inclusive."""
    if start > end:
        start, end = end, start
    return sum(range(start, end + 1))


def is_palindrome(text: str) -> bool:
    """Return True if text reads the same forwards and backwards."""
    cleaned = "".join(ch for ch in text if ch.isalnum())
    return cleaned.lower() == cleaned[::-1].lower()


def clamp(value: float, low: float, high: float) -> float:
    """Clamp value to [low, high]."""
    if low > high:
        low, high = high, low
    if value < low:
        return low
    if value > high:
        return high
    return value


def mean(values: list[float]) -> float:
    """Arithmetic mean; empty list returns 0.0."""
    if not values:
        return 0.0
    return sum(values) / len(values)


def median(values: list[float]) -> float:
    """Median of values; empty list returns 0.0."""
    if not values:
        return 0.0
    s = sorted(values)
    n = len(s)
    mid = n // 2
    if n % 2:
        return float(s[mid])
    return (float(s[mid - 1]) + float(s[mid])) / 2.0