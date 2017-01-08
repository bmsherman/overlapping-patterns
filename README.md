Overlapping Pattern Matching for Programming With Continuous Functions
-----

## Building

To build, run `make` at the base level of the project directory.

## Key definitions/theorems

The overlapping pattern matching construction (theorem 1 from the draft)
is found in `src/Sublocale.v` in the section called `Pattern`.

The computation rule for splitting points with open covers is found in
`src/FrameC.v` and has the identifier `point_cov_top`.

## Notes

This code was essentially extracted from a 
[much larger codebase](https://github.com/bmsherman/topology)
that provides various bits of functionality for programming with spaces,
including many constructions of formal topology and (predicative)
locale theory.
