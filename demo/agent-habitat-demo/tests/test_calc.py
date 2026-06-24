from habitat.calc import clamp, is_palindrome, sum_range


def test_sum_range_basic():
    assert sum_range(1, 5) == 15


def test_sum_range_reversed():
    assert sum_range(5, 1) == 15


def test_is_palindrome_simple():
    assert is_palindrome("racecar")
    assert is_palindrome("Racecar")
    assert not is_palindrome("hello")


def test_clamp():
    assert clamp(5, 0, 10) == 5
    assert clamp(-1, 0, 10) == 0
    assert clamp(99, 0, 10) == 10


def test_clamp_inverted_bounds():
    assert clamp(5, 10, 0) == 5