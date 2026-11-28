class_name Operations extends RefCounted

# Numbers in the game are integers from -MAX_VALUE to MAX_VALUE.
const MAX_VALUE := 9999


func mine(ore: int) -> int:
	return ore


func sum(a: int, b: int) -> Variant:
	var result := a + b
	return result if absi(result) <= MAX_VALUE else null


func subtract(a: int, b: int) -> Variant:
	var difference := a - b
	return difference if absi(difference) <= MAX_VALUE else null


func multiply(a: int, b: int) -> Variant:
	var result := a * b
	return result if absi(result) <= MAX_VALUE else null


func divide(a: int, b: int) -> Variant:
	if b == 0 or a % b != 0:
		return null
	@warning_ignore("integer_division")
	return a / b


func square(a: int) -> Variant:
	var result := a * a
	return result if absi(result) <= MAX_VALUE else null


func cube(a: int) -> Variant:
	var result := a * a * a
	return result if absi(result) <= MAX_VALUE else null


func power(a: int, b: int) -> Variant:
	if b < 0 or (a == 0 and b == 0):
		return null
	var result := 1
	for i in b:
		result *= a
		if absi(result) > MAX_VALUE:
			return null
	return result


func square_root(a: int) -> Variant:
	if a < 0:
		return null
	if a == 0:
		return 0
	var root := int(sqrt(a))
	# sqrt works in floats, so check the neighbours too.
	for candidate in [root - 1, root, root + 1]:
		if candidate >= 0 and candidate * candidate == a:
			return candidate
	return null


func factorial(n: int) -> Variant:
	if n < 0:
		return null
	var result := 1
	for i in range(2, n + 1):
		result *= i
		if result > MAX_VALUE:
			return null
	return result


func gcd(a: int, b: int) -> Variant:
	a = absi(a)
	b = absi(b)
	if a == 0 and b == 0:
		return null
	while b != 0:
		var remainder := a % b
		a = b
		b = remainder
	return a


func lcm(a: int, b: int) -> Variant:
	if a == 0 or b == 0:
		return null
	var divisor: Variant = gcd(a, b)
	if divisor == null:
		return null
	@warning_ignore("integer_division")
	var multiple: int = absi(a / int(divisor) * b)
	return multiple if multiple <= MAX_VALUE else null
