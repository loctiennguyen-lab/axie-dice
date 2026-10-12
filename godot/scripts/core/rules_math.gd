class_name RulesMath
extends RefCounted
## Rounding used by every new combat rule (L1 contract 3.1): .5 rounds UP, for positive and
## negative alike nothing else is meant (all callers pass values >= 0).
##
## GDScript's `round()` rounds half away from zero, which is the same for x >= 0, but spelling it
## as one named function keeps "half up" a decision made once. The tiny epsilon absorbs float
## products such as 10 * 1.15 = 11.499999999999998 landing a hair under the .5 they mean.

static func round_half_up(x: float) -> int:
	return int(floor(x + 0.5 + 1e-9))
