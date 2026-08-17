"""The real checker: a fixed spec for merge_intervals.

Never edit this file to make it pass. If a test here is wrong, that is a
finding to report, not a line to delete.
"""
import unittest

from intervals import merge_intervals


class MergeIntervalsTests(unittest.TestCase):
    def test_no_overlap(self):
        self.assertEqual(
            merge_intervals([(1, 2), (5, 6)]),
            [(1, 2), (5, 6)],
        )

    def test_simple_overlap(self):
        self.assertEqual(
            merge_intervals([(1, 4), (2, 5)]),
            [(1, 5)],
        )

    def test_touching_intervals_merge(self):
        # end of one == start of the next: no gap, so they must merge.
        self.assertEqual(
            merge_intervals([(1, 3), (3, 5)]),
            [(1, 5)],
        )

    def test_unsorted_input(self):
        self.assertEqual(
            merge_intervals([(5, 6), (1, 2)]),
            [(1, 2), (5, 6)],
        )

    def test_nested_interval(self):
        self.assertEqual(
            merge_intervals([(1, 10), (2, 3)]),
            [(1, 10)],
        )

    def test_empty_input(self):
        self.assertEqual(merge_intervals([]), [])

    def test_single_interval(self):
        self.assertEqual(merge_intervals([(1, 2)]), [(1, 2)])

    def test_three_way_chain(self):
        # (1,2) touches (2,3) touches (3,4): all three collapse into one.
        self.assertEqual(
            merge_intervals([(1, 2), (2, 3), (3, 4)]),
            [(1, 4)],
        )


if __name__ == "__main__":
    unittest.main()
