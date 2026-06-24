from habitat.calc import clamp, is_palindrome, mean, median, sum_range


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


def test_mean():
    assert mean([1, 2, 3, 4]) == 2.5
    assert mean([10, 20]) == 15.0


def test_mean_empty():
    assert mean([]) == 0.0


def test_median_odd():
    assert median([3, 1, 2]) == 2.0


def test_median_even():
    assert median([1, 2, 3, 4]) == 2.5


def test_median_empty():
    assert median([]) == 0.0