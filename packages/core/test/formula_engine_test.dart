import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to evaluate a formula with optional cell data
  dynamic eval(String formula, [Map<String, dynamic>? cells]) {
    final Map<String, dynamic> activeCells = cells ?? {};
    final engine = FormulaEngine(
      cellResolver: (ref) {
        final val = activeCells[ref];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val);
        return null;
      },
      textResolver: (ref) {
        final val = activeCells[ref];
        return val?.toString() ?? '';
      },
    );
    final result = engine.evaluate(formula);
    if (result.isError) {
      return result.errorMessage ?? '#ERROR!';
    }
    final val = result.value;
    if (val is bool) {
      return val ? 1.0 : 0.0;
    }
    return val;
  }

  group('FormulaEngine — Arithmetic', () {
    test('basic addition', () {
      expect(eval('=1+2'), equals(3.0));
    });

    test('subtraction', () {
      expect(eval('=10-4'), equals(6.0));
    });

    test('multiplication', () {
      expect(eval('=3*7'), equals(21.0));
    });

    test('division', () {
      expect(eval('=20/4'), equals(5.0));
    });

    test('division by zero returns error', () {
      final result = eval('=1/0');
      expect(result, isA<String>());
      expect(result.toString(), contains('DIV'));
    });

    test('parentheses change precedence', () {
      expect(eval('=(2+3)*4'), equals(20.0));
    });

    test('negative numbers', () {
      expect(eval('=-5+10'), equals(5.0));
    });
  });

  group('FormulaEngine — Math Functions', () {
    test('SUM with numbers', () {
      expect(eval('=SUM(1,2,3)'), equals(6.0));
    });

    test('AVERAGE', () {
      expect(eval('=AVERAGE(10,20,30)'), equals(20.0));
    });

    test('MIN', () {
      expect(eval('=MIN(5,2,8,1)'), equals(1.0));
    });

    test('MAX', () {
      expect(eval('=MAX(5,2,8,1)'), equals(8.0));
    });

    test('COUNT', () {
      expect(eval('=COUNT(1,2,3,4,5)'), equals(5.0));
    });

    test('ABS', () {
      expect(eval('=ABS(-42)'), equals(42.0));
    });

    test('ROUND', () {
      expect(eval('=ROUND(3.456,2)'), equals(3.46));
    });

    test('FLOOR', () {
      expect(eval('=FLOOR(3.7)'), equals(3.0));
    });

    test('CEILING', () {
      expect(eval('=CEILING(3.2)'), equals(4.0));
    });

    test('POWER', () {
      expect(eval('=POWER(2,10)'), equals(1024.0));
    });

    test('SQRT', () {
      expect(eval('=SQRT(144)'), equals(12.0));
    });

    test('MOD', () {
      expect(eval('=MOD(10,3)'), equals(1.0));
    });

    test('PI returns pi', () {
      expect(eval('=PI()'), closeTo(3.14159, 0.001));
    });
  });

  group('FormulaEngine — Text Functions', () {
    test('LEN', () {
      expect(eval('=LEN("Hello")'), equals(5.0));
    });

    test('UPPER', () {
      expect(eval('=UPPER("hello")'), equals('HELLO'));
    });

    test('LOWER', () {
      expect(eval('=LOWER("HELLO")'), equals('hello'));
    });

    test('TRIM', () {
      expect(eval('=TRIM("  hello  ")'), equals('hello'));
    });

    test('CONCATENATE', () {
      expect(eval('=CONCATENATE("Hello"," ","World")'), equals('Hello World'));
    });

    test('LEFT', () {
      expect(eval('=LEFT("Hello",3)'), equals('Hel'));
    });

    test('RIGHT', () {
      expect(eval('=RIGHT("Hello",3)'), equals('llo'));
    });

    test('MID', () {
      expect(eval('=MID("Hello World",7,5)'), equals('World'));
    });
  });

  group('FormulaEngine — Logical Functions', () {
    test('IF true condition', () {
      expect(eval('=IF(1,\"yes\",\"no\")'), equals('yes'));
    });

    test('IF false condition', () {
      expect(eval('=IF(0,\"yes\",\"no\")'), equals('no'));
    });

    test('AND', () {
      expect(eval('=AND(1,1,1)'), equals(1.0));
      expect(eval('=AND(1,0,1)'), equals(0.0));
    });

    test('OR', () {
      expect(eval('=OR(0,0,1)'), equals(1.0));
      expect(eval('=OR(0,0,0)'), equals(0.0));
    });

    test('NOT', () {
      expect(eval('=NOT(1)'), equals(0.0));
      expect(eval('=NOT(0)'), equals(1.0));
    });
  });

  group('FormulaEngine — Cell References', () {
    test('simple cell reference', () {
      expect(eval('=A1', {'A1': 42}), equals(42));
    });

    test('cell reference in formula', () {
      expect(eval('=A1+B1', {'A1': 10, 'B1': 20}), equals(30.0));
    });

    test('SUM with cell references', () {
      expect(eval('=SUM(A1,B1,C1)', {'A1': 1, 'B1': 2, 'C1': 3}), equals(6.0));
    });

    test('missing cell reference returns 0', () {
      expect(eval('=A1+1', {}), equals(1.0));
    });
  });

  group('FormulaEngine — Edge Cases', () {
    test('non-formula returns as-is', () {
      expect(eval('hello'), equals('hello'));
    });

    test('empty formula', () {
      expect(eval(''), equals(''));
    });

    test('number-only formula', () {
      expect(eval('=42'), equals(42.0));
    });

    test('nested function calls', () {
      expect(eval('=SUM(1,MAX(2,3),4)'), equals(8.0));
    });
  });

  group('FormulaEngine — Statistical Functions', () {
    test('MEDIAN odd count', () {
      expect(eval('=MEDIAN(1,3,5,7,9)'), equals(5.0));
    });

    test('MEDIAN even count', () {
      expect(eval('=MEDIAN(1,3,5,7)'), equals(4.0));
    });
  });
}
