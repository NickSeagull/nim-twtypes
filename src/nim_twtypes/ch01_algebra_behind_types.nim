{.push raises:[].}
{.push tags:[].}
include p
# Cardinality

# In Nim, one cannot instantiate `void`, like in TypeScript
# |void| = 0

# The Unit type in Nim is `type(nil)`, and to create a value it is `nil`
# you cannot instantiate `nil` into any type.
# |type(nil) = 1|

# |bool = 2|

# Isomorphisms

# If we can convert back and forth two types, we say that they are isomorphic
proc convertTo*[S, T](x: S): T = discard
proc convertFrom*[S, T](x: T): S = discard

# Isomorphism :
# 1. ` x.convertTo.convertFrom == id`
# 2. ` x.convertFrom.convertTo == id`

# Type isomorphic to `bool`:
variant Spin:
  Up
  Down

# Isomorphism 1
proc boolToSpin1*(b: bool): Spin =
  result = if b: Up() else: Down()

proc spinToBool1*(s: Spin): bool =
  match s:
    Up(): true
    Down(): false

# Isomorphism 2
proc boolToSpin2*(b: bool): Spin =
  result = if b: Down() else: Up()

proc spinToBool2*(s: Spin): bool =
  match s:
    Down(): true
    Up(): false

# Sum, product, and exponential types

# A sum type is a tagged union:
variant Either[A, B]:
  Left(l: A)
  Right(r: B)

# Here, |Either[A, B]| = |A| + |B|

# We can add as many branches to the
# variant, to sum more:
variant Deal[A, B]:
  This(this: A)
  That(that: B)
  TheOther(other: bool)

# And the cardinality would be:
# |Deal[A, B]| = |A| + |B| + |bool| = |A| + |B| + 2

# In the case of `Maybe`, the cardinality is:
# |Maybe[A]| = 1 + |A|
variant Maybe[A]:
  Just(x: A)
  Nothing

# Product types are tuples, because they will multiply
# the cardinalities
# |(A, B)| = |A| * |B|

# Objects are just tuples, e.g.
type
  MixedFraction*[A] = object
    mixedBit: int8
    numerator: A
    denominator: A

# In this case, |MixedFraction[A]| = |int8| * |A| * |A| = 256 * |A| * |A|

# We can prove that `a * 1 = a` by showing an isomorphism between `(A, nil)` and `A`:
proc prodNilTo*[A](a: A): (A, type(nil)) =
  (a, nil)

proc prodNilFrom*[A](t: (A, type(nil))): A =
  t.first

# We can also prove that `a + 0 = a` by showing an isomorsphism between `Either[A, void]` and A:
proc sumUnitTo*[A](x: Either[A, void]): A =
  match x:
    Left(@a): a
    Right(@b): discard

proc sumUnitFrom*[A](x: A): Either[A, void] =
  Left(x)

# Function types (`=>`) are exponential types.
# `A => B` has cardinality |B| ^ |A|. E.g.
# `bool => bool` has cardinality 2^2=4.

# This is because there are only 4 functions to
# convert between `bool`s:
# * id
# * not
# * constantly true
# * constantly false

# The explanation is that, for every possible value
# of input, there could be any possible value as an output
# |A => B| = |B| * |B| * ... * |B| = |B| ^ |A|
#            ^----- |A| times ---^

# Exercise 1.2-i
# Determine the cardinality of `Either[bool, (bool, Maybe[bool])] => bool`

# Solution:
# |Either[bool, (bool, Maybe[bool])] => bool| =
# |bool| ^ |Either[bool, (bool, Maybe[bool])]| =
# |bool| ^ (|bool| + |(bool, Maybe[bool])|) =
# |bool| ^ (|bool| + |bool| * |Maybe[bool]|) =
# |bool| ^ (|bool| + |bool| * (1 + |bool|)) =
# 2 ^ (2 + 2 * (1 + 2)) =
# 256

# Example: Tic-Tac-Toe

type
  TicTacToe[A] = tuple
    [
      topLeft: A,
      topCenter: A,
      topRight: A,
      midLeft: A,
      midCenter: A,
      midRight: A,
      botLeft: A,
      botCenter: A,
      botRight: A
    ]

# Here's a possible example, we have 9 cells due to the 9 fields:
proc emptyBoard*(): TicTacToe[Option[bool]] =
  (none(bool), none(bool), none(bool),
   none(bool), none(bool), none(bool),
   none(bool), none(bool), none(bool))

# |TicTacToe[A]| = |A| * |A| * ... * |A|  <- 9 times
# Which is something like
#   |A| ^ 9
#   |A| ^ 3*3
# Writing a `checkWinner` would be a lot to write.
# Now we know that we need to write something with cardinality |A| ^ 3*3
# So we can simplify the implementation by looking for something with cardinality 3*3
# Let's create a type that represents Three:
variant OneOfThree:
  One
  Two
  Three

# Now in order to multiply, this would be (Three, Three), and to exponentiate it, it would be
# a function: (Three, Three) -> A
# So we can simplify TicTacToe to this:
type
  TicTacToe2[A] = (r: OneOfThree, c: OneOfThree) -> A

# And rewrite emptyBoard:
proc emptyBoard2*(): TicTacToe2[Option[bool]] =
  (r: OneOfThree, c: OneOfThree) => none(bool)

# The Curry-Howard Isomorphism

# Exercise 1.4-i
# Use Curry-Howard to prove that (a^b)^c == a^(b*c). That is,
# provide a function of type `((x: b,y: c) -> a, (b, c)) -> a` and
# `((x: (b,c)) -> a) -> (x: b, y: c) -> a`.
func curry*[A, B, C](f: proc (x: B, y: C): A {.noSideEffect.}, x: (B, C)): A =
  f(x[0], x[1])

let _ = curry[type(nil), type(nil), type(nil)] # For instantiating generics

func uncurry*[A, B, C](f: proc (x: (B, C)): A): proc (x: B, y: C): A =
  (x: B, y: C) => x

let _ = uncurry[type(nil), type(nil), type(nil)]