import Cocoa

/*:
 
 # IOS @ ITMO 2022
 ## ДЗ №1
 ### Написать калькулятор
 1. Создать два типа IntegralCalculator и RealCalculator
 2. Поддержать для них протокол Calculator с типами Int и Double соответственно

 ### Бонус
 За удвоенные баллы:
 1. Поддержать унарный минус
 2. Поддержать скобки
 
 ### Критерии оценки
 0. Общая рациональность
 1. Корректность
 2. Красота и качество кода
*/

/// Пример использования
func testReal<T: Calculator>(calculator type: T.Type) where T.Number == Double {
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .left, function: -),
        "*": Operator(precedence: 20, associativity: .left, function: *),
        "/": Operator(precedence: 20, associativity: .left, function: /),
        "^": Operator(precedence: 100, associativity: .right, function: {a, b in return pow(a, b)}),
    ])

    var result: T.Number
    result = try! calculator.evaluate("1 / 0")
    assert(result == Double.infinity)
    result = try! calculator.evaluate("-1 / 0")
    assert(result == -Double.infinity)
    result = try! calculator.evaluate("1 / 0")
    assert(result == Double.infinity)
    result = try! calculator.evaluate("1 / 0")
    assert(result == Double.infinity)
    
}

func testInt<T: Calculator>(calculator type: T.Type) where T.Number == Int {
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .left, function: -),
        "&+": Operator(precedence: 10, associativity: .left, function: &+),
        "&-": Operator(precedence: 10, associativity: .left, function: &-),
        "*": Operator(precedence: 20, associativity: .left, function: *),
        "/": Operator(precedence: 20, associativity: .left, function: /),
        "^": Operator(precedence: 100, associativity: .right, function: {a, b in return Int(truncating: NSDecimalNumber(decimal: pow(Decimal(a), b)))}),

    ])

    var result: T.Number
    result = try! calculator.evaluate("1 + 2 * 5 * 6 / 3 - 7 ^ 2")
    assert(result == -28)
    result = try! calculator.evaluate("-9223372036854775808 + 1 - 1")
    assert(result == -9223372036854775808)
    result = try! calculator.evaluate("-9223372036854775808 &- 1 &+ 1")
    assert(result == -9223372036854775808)
    result = try! calculator.evaluate("9223372036854775807 - 1 + 1")
    assert(result == 9223372036854775807)
    result = try! calculator.evaluate("9223372036854775807 &+ 1 &- 1")
    assert(result == 9223372036854775807)
    
}

func testAssociativity<T: Calculator>(calculator type: T.Type) where T.Number == Int {
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .right, function: -),
        "*": Operator(precedence: 20, associativity: .left, function: *),
        "/": Operator(precedence: 20, associativity: .right, function: /),
        "^": Operator(precedence: 100, associativity: .right, function: {a, b in return T.Number(truncating: NSDecimalNumber(decimal: pow(Decimal(a), b)))}),

    ])

    var result: T.Number
    result = try! calculator.evaluate("2 ^ 3 ^ 2") // 2 ^ (3 ^ 2)
    assert(result == 512)
    result = try! calculator.evaluate("1 - 2 - 4") // 1 - (2 - 4)
    assert(result == 3)
    result = try! calculator.evaluate("1 + 2 + 3 - 4 - 5 + 6") // ((1 + 2) + (3 - (4 - (5 + 6))))
    // ((1 + 2) + 3 - (4 - 5) + 6
    assert(result == 13)
    result = try! calculator.evaluate("60 / 12 / 3") // 60 / (12 / 3)
    assert(result == 15)
}

func testPrecendences<T: Calculator>(calculator type: T.Type) {
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .left, function: -),
        "*": Operator(precedence: 20, associativity: .left, function: *),
        "@+": Operator(precedence: 110, associativity: .left, function: +),
        "@-": Operator(precedence: 110, associativity: .left, function: -),
        "@*": Operator(precedence: 120, associativity: .left, function: *),
        "#+": Operator(precedence: 210, associativity: .left, function: +),
        "#-": Operator(precedence: 210, associativity: .left, function: -),
        "#*": Operator(precedence: 220, associativity: .left, function: *),

    ])
    var result: T.Number
        result = try! calculator.evaluate("1 + 2 * 3 - 4") // 1 + (2 * 3) - 4
        assert(result == 3)
        result = try! calculator.evaluate("1 @+ 2 * 3 - 4") // ((1 + 2) * 3) - 4
        assert(result == 5)
        result = try! calculator.evaluate("1 + 2 * 3 @- 4") // 1 + (2 * (3 - 4))
        assert(result == -1)
        result = try! calculator.evaluate("1 - 2 @+ 3 - 4") // (1 - (2 + 3)) - 4
        assert(result == -8)
        result = try! calculator.evaluate("1 - 2 #+ 3 @- 4") // 1 - ((2 + 3) - 4)
        assert(result == 0)
    }

func testParentheses<T: Calculator>(calculator type: T.Type) where T.Number == Int {
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .left, function: -),
        "&+": Operator(precedence: 10, associativity: .left, function: &+),
        "&-": Operator(precedence: 10, associativity: .left, function: &-),
        "*": Operator(precedence: 20, associativity: .left, function: *),
        "/": Operator(precedence: 20, associativity: .left, function: /),
        "^": Operator(precedence: 100, associativity: .right, function: {a, b in return Int(truncating: NSDecimalNumber(decimal: pow(Decimal(a), b)))}),

    ])

    var result: T.Number
    result = try! calculator.evaluate("1 - (3 - 4)")
    assert(result == 2)
    result = try! calculator.evaluate("((((1 - (3 - 4)))))")
    assert(result == 2)
    result = try! calculator.evaluate("((((1)))) - (3 - 4)")
    assert(result == 2)
    result = try! calculator.evaluate("1 - (((3)) - (4 + (1 - 1)))")
    assert(result == 2)
    result = try! calculator.evaluate("2 * (3 + 4)")
    assert(result == 14)
}


func testUnaryMinus<T: Calculator>(calculator type: T.Type){
    let calculator = type.init(operators: [
        "+": Operator(precedence: 10, associativity: .left, function: +),
        "-": Operator(precedence: 10, associativity: .left, function: -),
        "*": Operator(precedence: 20, associativity: .left, function: *),
    ])
    
    var result: T.Number
    result = try! calculator.evaluate("-(3 + 4) * 2")
    assert(result == -14)
    result = try! calculator.evaluate("-(-(9223372036854775807))")
    assert(result == 9223372036854775807)
    result = try! calculator.evaluate("-(5 + 4) + -(1 - 5)")
    assert(result == -5)
    result = try! calculator.evaluate("-(5 + 4) + -(1 - 5) * --(4)")
    assert(result == 7)
}

testInt(calculator: IntegerCalculator.self)
testReal(calculator: RealCalculator.self)
testAssociativity(calculator: IntegerCalculator.self)
testPrecendences(calculator: IntegerCalculator.self)
testParentheses(calculator: IntegerCalculator.self)
testPrecendences(calculator: RealCalculator.self)
testUnaryMinus(calculator: IntegerCalculator.self)
testUnaryMinus(calculator: RealCalculator.self)
print("All tests are good")
