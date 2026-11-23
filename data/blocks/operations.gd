class_name Operations extends RefCounted

# Numbers in the game are whole numbers from 1 up to this; item_view.gd fits at most four digits on an item.
const MAX_VALUE := 9999


func mine(ore: int) -> int:
	return ore


func sum(a: int, b: int) -> int:
	return a + b


func subtract(a: int, b: int) -> Variant:
	var difference := a - b
	return difference if difference > 0 else null


func multiply(a: int, b: int) -> int:
	return a * b


func divide(a: int, b: int) -> Variant:
	if b == 0 or a % b != 0:
		return null
	@warning_ignore("integer_division")
	return a / b


func square(a: int) -> int:
	return a * a


func cube(a: int) -> int:
	return a * a * a


func power(a: int, b: int) -> Variant:
	if a < 1 or b < 1:
		return null
	var result := 1
	for i in b:
		result *= a
		if result > MAX_VALUE:
			return null
	return result


func square_root(a: int) -> Variant:
	if a < 1:
		return null
	var root := int(sqrt(a))
	# sqrt works in floats, so check the neighbours too.
	for candidate in [root - 1, root, root + 1]:
		if candidate >= 1 and candidate * candidate == a:
			return candidate
	return null


func factorial(n: int) -> Variant:
	if n < 1:
		return null
	var result := 1
	for i in range(2, n + 1):
		result *= i
		if result > MAX_VALUE:
			return null
	return result


func gcd(a: int, b: int) -> Variant:
	if a < 1 or b < 1:
		return null
	while b != 0:
		var remainder := a % b
		a = b
		b = remainder
	return a


func lcm(a: int, b: int) -> Variant:
	var divisor: Variant = gcd(a, b)
	if divisor == null:
		return null
	@warning_ignore("integer_division")
	var multiple: int = a / int(divisor) * b
	return multiple if multiple <= MAX_VALUE else null
