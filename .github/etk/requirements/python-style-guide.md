# Python Coding Standard

1. All public functions must have a docstring describing purpose, arguments, and return value.
2. Variable and function names must be descriptive (no single-letter names except loop indices).
3. Division operations must guard against a zero divisor and raise a clear error instead of letting `ZeroDivisionError` propagate.
4. Functions must not use bare `elif` chains for more than 3 branches — prefer a dispatch dict or `match` statement.

Replace this file with the repo's actual Python style guide. The pipeline uploads whatever is at
this path to S3 as the requirement doc the `agent-as-judge` evaluator judges each PR diff against.
