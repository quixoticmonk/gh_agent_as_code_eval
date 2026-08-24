def calc(a, b, op):
    """Perform a basic arithmetic operation on two numbers.

    Args:
        a: The first operand.
        b: The second operand.
        op: One of "add", "sub", "mul", "div".

    Returns:
        The result of applying op to a and b.
    """
    if op == "add":
        return a + b
    elif op == "sub":
        return a - b
    elif op == "mul":
        return a * b
    elif op == "div":
        return a / b
