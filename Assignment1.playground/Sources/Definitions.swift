import Foundation

public enum Associativity {
    case left, right, none
}

public struct Operator<T: Numeric> {
    public let precedence: Int
    public let associativity: Associativity
    private let function: (T, T) throws -> T
    
    public init(precedence: Int, associativity: Associativity, function: @escaping (T, T) -> T) {
        self.precedence = precedence
        self.associativity = associativity
        self.function = function
    }
    
    public func apply(_ lhs: T, _ rhs: T) throws -> T {
        try self.function(lhs, rhs)
    }
}

class Expression<Number: Numeric & LosslessStringConvertible> {

    func evaluate() throws -> Number {
        throw ParserError.DevelopeError(message: "evaluate must be overwrited")
    }
    
    func toString() throws -> String {
        throw ParserError.DevelopeError(message: "toString must be overwrited")
    }

    func simplify() throws -> Expression<Number> {
        throw ParserError.DevelopeError(message: "simplify must be overwrited")
    }
}

class Const <Number: Numeric & LosslessStringConvertible>: Expression<Number> {
    let n: Number
    
    init(_ n: Number) {
        self.n = n
    }
    
    override func evaluate() throws -> Number {
        return n
    }
    
    override func toString() throws -> String {
        return String(n)
    }
    
    override func simplify() throws -> Expression<Number> {
        return self
    }
}

class Negate <Number: Numeric & LosslessStringConvertible>: Expression<Number> {
    let expr: Expression<Number>
    
    init(_ expr: Expression<Number>) {
        self.expr = expr
    }
    
    override func evaluate() throws -> Number {
        return -1 * (try expr.evaluate())
    }
    
    override func toString() throws -> String {
        return "-(\(try expr.toString()))"
    }
    
    override func simplify() throws -> Expression<Number> {
        return BinaryExpression(Const(-1), try expr.simplify(), Operator<Number>(precedence: 9223372036854775807, associativity: .left, function: *), "*")
    }
}

class BinaryExpression<Number: Numeric & LosslessStringConvertible>: Expression<Number> {
    let lhs: Expression<Number>
    let rhs: Expression<Number>
    let operation: Operator<Number>
    let sign: String
    
    init(_ lhs: Expression<Number>, _ rhs: Expression<Number>, _ operation: Operator<Number>, _ sign: String) {
        self.lhs = lhs
        self.rhs = rhs
        self.operation = operation
        self.sign = sign
    }
    
    override func evaluate() throws -> Number {
        return try operation.apply(lhs.evaluate(), rhs.evaluate())
    }
    
    override func toString() throws -> String {
        return "(\(try lhs.toString()) \(sign) \(try rhs.toString()))"
    }

    override func simplify() throws -> Expression<Number> {
        if (self.sign == "+") && (self.rhs is Negate) {
            return BinaryExpression(try self.lhs.simplify(), try (self.rhs as! Negate<Number>).expr.simplify(), Operator<Number>(precedence: self.operation.precedence, associativity: self.operation.associativity, function: -), "-")
        }
        if (self.sign == "-") && (self.rhs is Negate) {
            return BinaryExpression(try self.lhs.simplify(), try (self.rhs as! Negate<Number>).expr.simplify(), Operator<Number>(precedence: self.operation.precedence, associativity: self.operation.associativity, function: +), "+")
        }
        return BinaryExpression(try lhs.simplify(), try rhs.simplify(), operation, sign)
    }
}



enum ParserError: Error {
    case InvalidDataError(message: String)
    case DevelopeError(message: String)
}

extension String {
    mutating func skipWhiteSpaces() {
        self = self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class ExpressionParser<Number: Numeric & LosslessStringConvertible> {
    var str: String
    let operators: Dictionary<String, Operator<Number>>
    
    init(_ str: String, _ operators: Dictionary<String, Operator<Number>>) {
        self.str = str
        self.operators = operators
    }
    
    func getOperation() -> String {
        var result = ""
        var x = str.startIndex

        while (!str.isEmpty && !str.first!.isNumber  && str.first != ")" && !str[x].isWhitespace) {
            result.append(String(str[x]))
            x = str.index(after: x)
        }
        return result
    }
    
    func parseOperation (_ firstOperand: Expression<Number>) throws -> Expression<Number> {
        let result = getOperation()
        str.removeFirst(result.count)
        if !result.isEmpty, let operation = operators[result] { //??
            return BinaryExpression.init(firstOperand, try parseSecondOperand(operation), operation, result)
        }
        throw ParserError.InvalidDataError(message: "Expected operation")
    }
    
    func parseSecondOperand(_ operation: Operator<Number>) throws -> Expression<Number> {
        str.skipWhiteSpaces()
        var secondOperand = try parseOperand()
        str.skipWhiteSpaces()
        var op = getOperation()
        while !str.isEmpty, str.first != ")", let next = operators[op],
              ((operation.precedence < next.precedence)
                    || ((operation.precedence == next.precedence)
                            && (operation.associativity == next.associativity && operation.associativity == .right) ) )  {
            secondOperand = try parseOperation(secondOperand)
            str.skipWhiteSpaces()
            op = getOperation()
        }
        return secondOperand
    }
    
    func parseOperand() throws -> Expression<Number> {
        guard !str.isEmpty else {
            throw ParserError.InvalidDataError(message: "Expected operand, found empty string")
        }
        
        if str.first! == "-" && str.count > 1 && !str[str.index(after: str.startIndex)].isNumber {
            str.removeFirst()
            return Negate.init(try parseOperand())
        }
        
        if str.first == "(" {
            str.removeFirst()
            let result = try parse()
            if str.removeFirst() == ")" {
                return result
            }
            throw ParserError.InvalidDataError(message: "Expected )")
        }
        
        var result = ""
        while (!str.isEmpty && !str.first!.isWhitespace && str.first! != ")") {
            result.append(str.first!)
            str.removeFirst()
        }
        if !result.isEmpty {
            return Const.init(Number(result)!)
        }
        
        throw ParserError.InvalidDataError(message: "Expected operand, found unknown sign")
    }
    
    func parse() throws -> Expression<Number> {
        str.skipWhiteSpaces()
        var result = try parseOperand()
        str.skipWhiteSpaces()
        while !str.isEmpty && str.first != ")" {
            result = try parseOperation(result)
            str.skipWhiteSpaces()
        }
        return result
    }
    
}

public protocol Calculator {
    associatedtype Number: Numeric

    init(operators: Dictionary<String, Operator<Number>>)

    func evaluate(_ input: String) throws -> Number
    
}

public class AbstractCalculator<Number: Numeric & LosslessStringConvertible> : Calculator {
    
    let operators: Dictionary<String, Operator<Number>>
    
    required public init(operators: Dictionary<String, Operator<Number>>) {
        self.operators = operators
    }
    public func evaluate(_ input: String) throws -> Number {
        let expression = try ExpressionParser<Number>.init(input, operators).parse()
        print(try expression.toString())
        return try expression.evaluate();
    }
    
}

public typealias IntegerCalculator = AbstractCalculator<Int>
public typealias RealCalculator = AbstractCalculator<Double>
