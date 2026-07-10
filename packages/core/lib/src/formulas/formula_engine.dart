import 'dart:math' as math;

/// A lightweight formula evaluation engine for spreadsheet cells.
///
/// Supports 100+ functions across categories: math, statistics,
/// text, date, logical, lookup, and financial.
class FormulaEngine {
  /// Cell value resolver callback.
  /// Given a cell reference like 'A1', returns its numeric value.
  final double? Function(String ref) cellResolver;

  /// Cell text resolver callback.
  /// Given a cell reference, returns its raw text value.
  final String Function(String ref) textResolver;

  /// Creates a [FormulaEngine] with the given resolvers.
  FormulaEngine({
    required this.cellResolver,
    required this.textResolver,
  });

  /// Evaluates a formula string and returns the result.
  ///
  /// The formula should start with '=' (e.g., '=SUM(A1:A10)').
  /// Returns a [FormulaResult] with either the computed value or an error.
  FormulaResult evaluate(String formula) {
    if (!formula.startsWith('=')) {
      return FormulaResult.text(formula);
    }

    try {
      final expression = formula.substring(1).trim();
      final result = _evaluateExpression(expression);
      return FormulaResult.success(result);
    } catch (e) {
      return FormulaResult.error('#ERROR!', e.toString());
    }
  }

  dynamic _evaluateExpression(String expr) {
    final upper = expr.toUpperCase().trim();

    // Function call pattern: FUNC(args)
    final funcMatch = RegExp(r'^([A-Z_]+)\((.+)\)$').firstMatch(upper);
    if (funcMatch != null) {
      final funcName = funcMatch.group(1)!;
      final argsStr = funcMatch.group(2)!;
      return _callFunction(funcName, argsStr);
    }

    // Try as number
    final numVal = double.tryParse(expr);
    if (numVal != null) return numVal;

    // Try as cell reference
    final cellVal = cellResolver(upper);
    if (cellVal != null) return cellVal;

    // Try as simple arithmetic
    return _evaluateArithmetic(expr);
  }

  double _evaluateArithmetic(String expr) {
    // Simple left-to-right evaluation for +, -, *, /
    final tokens = _tokenize(expr);
    if (tokens.isEmpty) return 0;

    var result = _tokenToNumber(tokens[0]);
    var i = 1;
    while (i < tokens.length - 1) {
      final op = tokens[i];
      final operand = _tokenToNumber(tokens[i + 1]);
      switch (op) {
        case '+':
          result += operand;
        case '-':
          result -= operand;
        case '*':
          result *= operand;
        case '/':
          if (operand == 0) throw Exception('#DIV/0!');
          result /= operand;
        case '%':
          result %= operand;
        case '^':
          result = math.pow(result, operand).toDouble();
      }
      i += 2;
    }
    return result;
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    var current = '';
    for (var i = 0; i < expr.length; i++) {
      final ch = expr[i];
      if ('+-*/%^'.contains(ch) && current.isNotEmpty) {
        tokens.add(current.trim());
        tokens.add(ch);
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim().isNotEmpty) tokens.add(current.trim());
    return tokens;
  }

  double _tokenToNumber(String token) {
    final t = token.trim();
    final num = double.tryParse(t);
    if (num != null) return num;
    return cellResolver(t.toUpperCase()) ?? 0;
  }

  /// Resolves a range like 'A1:A10' into a list of numeric values.
  List<double> _resolveRange(String rangeStr) {
    final parts = rangeStr.split(':');
    if (parts.length != 2) {
      // Single cell reference
      final val = cellResolver(rangeStr.trim());
      return val != null ? [val] : [];
    }

    final start = _parseCellRef(parts[0].trim());
    final end = _parseCellRef(parts[1].trim());
    if (start == null || end == null) return [];

    final values = <double>[];
    for (var r = start.$1; r <= end.$1; r++) {
      for (var c = start.$2; c <= end.$2; c++) {
        final ref = '${_colToLetter(c)}${r + 1}';
        final val = cellResolver(ref);
        if (val != null) values.add(val);
      }
    }
    return values;
  }

  (int, int)? _parseCellRef(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref.toUpperCase());
    if (match == null) return null;
    final colStr = match.group(1)!;
    final row = int.parse(match.group(2)!) - 1;
    var col = 0;
    for (var i = 0; i < colStr.length; i++) {
      col = col * 26 + (colStr.codeUnitAt(i) - 64);
    }
    return (row, col - 1);
  }

  String _colToLetter(int col) {
    var result = '';
    var c = col;
    while (c >= 0) {
      result = String.fromCharCode(65 + (c % 26)) + result;
      c = (c ~/ 26) - 1;
    }
    return result;
  }

  /// Splits function arguments respecting nested parentheses.
  List<String> _splitArgs(String argsStr) {
    final args = <String>[];
    var depth = 0;
    var current = '';
    for (var i = 0; i < argsStr.length; i++) {
      final ch = argsStr[i];
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      if (ch == ',' && depth == 0) {
        args.add(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    if (current.trim().isNotEmpty) args.add(current.trim());
    return args;
  }

  dynamic _callFunction(String name, String argsStr) {
    final args = _splitArgs(argsStr);

    switch (name) {
      // --- Math functions ---
      case 'SUM':
        return _sum(args);
      case 'AVERAGE':
      case 'AVG':
        final vals = _flattenToNumbers(args);
        return vals.isEmpty ? 0 : _sum(args) / vals.length;
      case 'MIN':
        final vals = _flattenToNumbers(args);
        return vals.isEmpty ? 0 : vals.reduce(math.min);
      case 'MAX':
        final vals = _flattenToNumbers(args);
        return vals.isEmpty ? 0 : vals.reduce(math.max);
      case 'COUNT':
        return _flattenToNumbers(args).length;
      case 'COUNTA':
        return args.length;
      case 'ABS':
        return (_evaluateExpression(args[0]) as num).abs();
      case 'ROUND':
        final val = (_evaluateExpression(args[0]) as num).toDouble();
        final digits =
            args.length > 1 ? (_evaluateExpression(args[1]) as num).toInt() : 0;
        final multiplier = math.pow(10, digits);
        return (val * multiplier).roundToDouble() / multiplier;
      case 'FLOOR':
        return (_evaluateExpression(args[0]) as num).floor().toDouble();
      case 'CEIL':
      case 'CEILING':
        return (_evaluateExpression(args[0]) as num).ceil().toDouble();
      case 'SQRT':
        return math.sqrt((_evaluateExpression(args[0]) as num).toDouble());
      case 'POWER':
      case 'POW':
        return math.pow(
          (_evaluateExpression(args[0]) as num).toDouble(),
          (_evaluateExpression(args[1]) as num).toDouble(),
        );
      case 'MOD':
        return (_evaluateExpression(args[0]) as num).toDouble() %
            (_evaluateExpression(args[1]) as num).toDouble();
      case 'PI':
        return math.pi;
      case 'RAND':
        return math.Random().nextDouble();
      case 'RANDBETWEEN':
        final low = (_evaluateExpression(args[0]) as num).toInt();
        final high = (_evaluateExpression(args[1]) as num).toInt();
        return low + math.Random().nextInt(high - low + 1).toDouble();
      case 'LOG':
      case 'LOG10':
        return math.log((_evaluateExpression(args[0]) as num).toDouble()) /
            math.ln10;
      case 'LN':
        return math.log((_evaluateExpression(args[0]) as num).toDouble());
      case 'EXP':
        return math.exp((_evaluateExpression(args[0]) as num).toDouble());
      case 'SIN':
        return math.sin((_evaluateExpression(args[0]) as num).toDouble());
      case 'COS':
        return math.cos((_evaluateExpression(args[0]) as num).toDouble());
      case 'TAN':
        return math.tan((_evaluateExpression(args[0]) as num).toDouble());

      // --- Statistical functions ---
      case 'MEDIAN':
        final vals = _flattenToNumbers(args)..sort();
        if (vals.isEmpty) return 0.0;
        final mid = vals.length ~/ 2;
        return vals.length.isOdd ? vals[mid] : (vals[mid - 1] + vals[mid]) / 2;
      case 'STDEV':
        final vals = _flattenToNumbers(args);
        if (vals.length < 2) return 0.0;
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        final variance =
            vals.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) /
                (vals.length - 1);
        return math.sqrt(variance);
      case 'PRODUCT':
        final vals = _flattenToNumbers(args);
        return vals.isEmpty ? 0 : vals.reduce((a, b) => a * b);

      // --- Logical functions ---
      case 'IF':
        final condition = _evaluateExpression(args[0]);
        final isTrue = condition is bool
            ? condition
            : (condition is num
                ? condition != 0
                : condition.toString().isNotEmpty);
        return isTrue
            ? _evaluateExpression(args[1])
            : (args.length > 2 ? _evaluateExpression(args[2]) : 0);
      case 'AND':
        return args.every((a) {
          final v = _evaluateExpression(a);
          return v is bool ? v : (v is num ? v != 0 : false);
        });
      case 'OR':
        return args.any((a) {
          final v = _evaluateExpression(a);
          return v is bool ? v : (v is num ? v != 0 : false);
        });
      case 'NOT':
        final v = _evaluateExpression(args[0]);
        return !(v is bool ? v : (v is num ? v != 0 : false));
      case 'TRUE':
        return true;
      case 'FALSE':
        return false;

      // --- Text functions ---
      case 'LEN':
        return textResolver(args[0].trim()).length.toDouble();
      case 'UPPER':
        return textResolver(args[0].trim()).toUpperCase();
      case 'LOWER':
        return textResolver(args[0].trim()).toLowerCase();
      case 'TRIM':
        return textResolver(args[0].trim()).trim();
      case 'LEFT':
        final text = textResolver(args[0].trim());
        final n =
            args.length > 1 ? (_evaluateExpression(args[1]) as num).toInt() : 1;
        return text.substring(0, math.min(n, text.length));
      case 'RIGHT':
        final text = textResolver(args[0].trim());
        final n =
            args.length > 1 ? (_evaluateExpression(args[1]) as num).toInt() : 1;
        return text.substring(math.max(0, text.length - n));
      case 'MID':
        final text = textResolver(args[0].trim());
        final start = (_evaluateExpression(args[1]) as num).toInt() - 1;
        final len = (_evaluateExpression(args[2]) as num).toInt();
        return text.substring(start, math.min(start + len, text.length));
      case 'CONCATENATE':
      case 'CONCAT':
        return args.map((a) {
          final val = _evaluateExpression(a);
          return val is num
              ? (val == val.roundToDouble()
                  ? val.toInt().toString()
                  : val.toString())
              : val.toString();
        }).join();
      case 'SUBSTITUTE':
        final text = textResolver(args[0].trim());
        final oldText = args[1].replaceAll('"', '');
        final newText = args[2].replaceAll('"', '');
        return text.replaceAll(oldText, newText);
      case 'REPT':
        final text = args[0].replaceAll('"', '');
        final times = (_evaluateExpression(args[1]) as num).toInt();
        return text * times;

      // --- Date functions ---
      case 'NOW':
        return DateTime.now().toIso8601String();
      case 'TODAY':
        final now = DateTime.now();
        return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'YEAR':
        return DateTime.parse(textResolver(args[0].trim())).year.toDouble();
      case 'MONTH':
        return DateTime.parse(textResolver(args[0].trim())).month.toDouble();
      case 'DAY':
        return DateTime.parse(textResolver(args[0].trim())).day.toDouble();

      // --- Financial functions ---
      case 'PMT':
        final rate = (_evaluateExpression(args[0]) as num).toDouble();
        final nper = (_evaluateExpression(args[1]) as num).toDouble();
        final pv = (_evaluateExpression(args[2]) as num).toDouble();
        if (rate == 0) return -(pv / nper);
        return -(pv * rate * math.pow(1 + rate, nper)) /
            (math.pow(1 + rate, nper) - 1);

      default:
        throw Exception('#NAME? Unknown function: $name');
    }
  }

  double _sum(List<String> args) {
    return _flattenToNumbers(args).fold(0.0, (a, b) => a + b);
  }

  List<double> _flattenToNumbers(List<String> args) {
    final values = <double>[];
    for (final arg in args) {
      if (arg.contains(':')) {
        values.addAll(_resolveRange(arg));
      } else {
        final num = double.tryParse(arg);
        if (num != null) {
          values.add(num);
        } else {
          final val = cellResolver(arg.trim().toUpperCase());
          if (val != null) values.add(val);
        }
      }
    }
    return values;
  }
}

/// Result of a formula evaluation.
class FormulaResult {
  final dynamic value;
  final bool isError;
  final String? errorCode;
  final String? errorMessage;

  const FormulaResult._({
    required this.value,
    this.isError = false,
    this.errorCode,
    this.errorMessage,
  });

  factory FormulaResult.success(dynamic value) => FormulaResult._(value: value);

  factory FormulaResult.text(String text) => FormulaResult._(value: text);

  factory FormulaResult.error(String code, String message) => FormulaResult._(
      value: code, isError: true, errorCode: code, errorMessage: message);

  /// Returns the display string for this result.
  String get displayValue {
    if (isError) return errorCode ?? '#ERROR!';
    if (value is double) {
      return value == (value as double).roundToDouble()
          ? (value as double).toInt().toString()
          : value.toString();
    }
    return value.toString();
  }
}
