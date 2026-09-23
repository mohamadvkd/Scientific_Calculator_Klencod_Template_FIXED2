import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scientific Calculator',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D10),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String expression = '';
  String result = '0';

  double ans = 0;
  double memory = 0;

  bool shift = false;
  bool second = false;
  bool degrees = true;

  final List<String> history = [];

  static const int maxExpressionLength = 1000;

  void setExpression(String value) {
    if (value.length > maxExpressionLength) {
      value = value.substring(0, maxExpressionLength);
    }

    setState(() {
      expression = value;
    });
  }

  void insert(String value) {
    if (expression.length >= maxExpressionLength) return;

    setState(() {
      expression += value;

      if (expression.length > maxExpressionLength) {
        expression = expression.substring(0, maxExpressionLength);
      }
    });
  }

  void clearAll() {
    setState(() {
      expression = '';
      result = '0';
    });
  }

  void deleteLast() {
    if (expression.isEmpty) return;

    setState(() {
      expression = expression.substring(0, expression.length - 1);
    });
  }

  void toggleShift() {
    setState(() {
      shift = !shift;
    });
  }

  void toggleSecond() {
    setState(() {
      second = !second;
    });
  }

  void toggleAngleMode() {
    setState(() {
      degrees = !degrees;
    });
  }

  double? evaluateExpression() {
    if (expression.trim().isEmpty) return null;

    try {
      final parser = ExpressionParser(
        expression,
        ans: ans,
        degrees: degrees,
      );

      final value = parser.parse();

      if (value.isNaN || value.isInfinite) {
        throw const FormatException('Invalid result');
      }

      return value;
    } catch (_) {
      return null;
    }
  }

  String formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    if (value.abs() < 1e-12) {
      value = 0;
    }

    final absValue = value.abs();

    if (absValue >= 1e12 || (absValue > 0 && absValue < 1e-10)) {
      return value
          .toStringAsExponential(10)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    String text = value.toStringAsFixed(12);

    text = text.replaceFirst(RegExp(r'\.?0+$'), '');

    if (text == '-0') {
      text = '0';
    }

    return text;
  }

  void calculate() {
    if (expression.trim().isEmpty) return;

    final value = evaluateExpression();

    if (value == null) {
      setState(() {
        result = 'Error';
      });
      return;
    }

    final formatted = formatNumber(value);

    setState(() {
      ans = value;
      result = formatted;

      history.insert(
        0,
        '${expression} = $formatted',
      );

      if (history.length > 100) {
        history.removeLast();
      }
    });
  }

  void applyUnary(String function) {
    if (expression.isEmpty) return;

    insert('$function(');
  }

  void applyPower(String power) {
    if (expression.isEmpty) return;
    insert('^$power');
  }

  void memoryAdd() {
    final value = evaluateExpression();

    if (value == null) return;

    setState(() {
      memory += value;
    });
  }

  void memorySubtract() {
    final value = evaluateExpression();

    if (value == null) return;

    setState(() {
      memory -= value;
    });
  }

  void memoryRecall() {
    insert(formatNumber(memory));
  }

  void memoryClear() {
    setState(() {
      memory = 0;
    });
  }

  Future<void> copyResult() async {
    final text = result;

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ النتيجة'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  void showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111419),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (history.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            history.clear();
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text(
                            'No calculations yet',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];

                            return ListTile(
                              title: Text(
                                item,
                                textAlign: TextAlign.right,
                              ),
                              onTap: () {
                                final position = item.lastIndexOf('=');

                                if (position > 0) {
                                  final exp = item
                                      .substring(0, position)
                                      .trim();

                                  setExpression(exp);
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void handleKey(String key) {
    switch (key) {
      case 'AC':
        clearAll();
        return;

      case 'DEL':
        deleteLast();
        return;

      case '=':
        calculate();
        return;

      case 'SHIFT':
        toggleShift();
        return;

      case '2nd':
        toggleSecond();
        return;

      case 'DEG/RAD':
        toggleAngleMode();
        return;

      case 'HIST':
        showHistory();
        return;

      case 'COPY':
        copyResult();
        return;

      case 'MC':
        memoryClear();
        return;

      case 'M+':
        memoryAdd();
        return;

      case 'M-':
        memorySubtract();
        return;

      case 'RCL':
        memoryRecall();
        return;

      case 'SIN':
        if (shift) {
          insert(second ? 'asinh(' : 'asin(');
        } else {
          insert(second ? 'sinh(' : 'sin(');
        }
        return;

      case 'COS':
        if (shift) {
          insert(second ? 'acosh(' : 'acos(');
        } else {
          insert(second ? 'cosh(' : 'cos(');
        }
        return;

      case 'TAN':
        if (shift) {
          insert(second ? 'atanh(' : 'atan(');
        } else {
          insert(second ? 'tanh(' : 'tan(');
        }
        return;

      case 'LOG':
        insert(shift ? '10^(' : 'log(');
        return;

      case 'LN':
        insert(shift ? 'exp(' : 'ln(');
        return;

      case 'SQRT':
        insert('sqrt(');
        return;

      case 'CBRT':
        insert('cbrt(');
        return;

      case 'ABS':
        insert('abs(');
        return;

      case 'FLOOR':
        insert('floor(');
        return;

      case 'CEIL':
        insert('ceil(');
        return;

      case 'FACT':
        insert('!');
        return;

      case 'NPR':
        insert('nPr(');
        return;

      case 'NCR':
        insert('nCr(');
        return;

      case 'GCD':
        insert('gcd(');
        return;

      case 'LCM':
        insert('lcm(');
        return;

      case 'MOD':
        insert(' mod ');
        return;

      case 'PI':
        insert('π');
        return;

      case 'E':
        insert('e');
        return;

      case 'ANS':
        insert('Ans');
        return;

      case 'POWER2':
        applyPower('2');
        return;

      case 'POWER3':
        applyPower('3');
        return;

      case 'INV':
        applyPower('-1');
        return;

      case 'EXP':
        insert('E');
        return;

      case 'SIGN':
        insert('(-');
        return;

      default:
        insert(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D10),
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Scientific Calculator',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy result',
            onPressed: copyResult,
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: showHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CalculatorDisplay(
              expression: expression,
              result: result,
              degrees: degrees,
              shift: shift,
              second: second,
              memory: memory != 0,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CalculatorKeyboard(
                shift: shift,
                second: second,
                degrees: degrees,
                onKey: handleKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String result;
  final bool degrees;
  final bool shift;
  final bool second;
  final bool memory;

  const CalculatorDisplay({
    super.key,
    required this.expression,
    required this.result,
    required this.degrees,
    required this.shift,
    required this.second,
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF11151A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _DisplayBadge(
                text: degrees ? 'DEG' : 'RAD',
                active: true,
              ),
              const SizedBox(width: 7),
              if (shift)
                const _DisplayBadge(
                  text: 'SHIFT',
                  active: true,
                ),
              if (second) ...[
                const SizedBox(width: 7),
                const _DisplayBadge(
                  text: '2nd',
                  active: true,
                ),
              ],
              if (memory) ...[
                const SizedBox(width: 7),
                const _DisplayBadge(
                  text: 'M',
                  active: true,
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.calculate_outlined,
                size: 19,
                color: Colors.white38,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 43,
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.horizontal,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  expression.isEmpty ? '0' : expression,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 58,
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.horizontal,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  result,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayBadge extends StatelessWidget {
  final String text;
  final bool active;

  const _DisplayBadge({
    required this.text,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF24313B)
            : Colors.white10,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}

class CalculatorKeyboard extends StatelessWidget {
  final bool shift;
  final bool second;
  final bool degrees;
  final ValueChanged<String> onKey;

  const CalculatorKeyboard({
    super.key,
    required this.shift,
    required this.second,
    required this.degrees,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    final keys = <CalcButtonData>[
      CalcButtonData(
        shift ? 'SHIFT ✓' : 'SHIFT',
        'SHIFT',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        second ? '2nd ✓' : '2nd',
        '2nd',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        degrees ? 'DEG' : 'RAD',
        'DEG/RAD',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'HIST',
        'HIST',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'COPY',
        'COPY',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'AC',
        'AC',
        type: CalcButtonType.danger,
      ),

      CalcButtonData(
        shift ? 'asin' : 'sin',
        'SIN',
        type: CalcButtonType.scientific,
      ),
      CalcButtonData(
        shift ? 'acos' : 'cos',
        'COS',
        type: CalcButtonType.scientific,
      ),
      CalcButtonData(
        shift ? 'atan' : 'tan',
        'TAN',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        '√',
        'SQRT',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        '∛',
        'CBRT',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'x⁻¹',
        'INV',
        type: CalcButtonType.scientific,
      ),

      CalcButtonData(
        shift ? '10ˣ' : 'log',
        'LOG',
        type: CalcButtonType.scientific,
      ),
      CalcButtonData(
        shift ? 'eˣ' : 'ln',
        'LN',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'x²',
        'POWER2',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'x³',
        'POWER3',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'xʸ',
        '^',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        '!',
        'FACT',
        type: CalcButtonType.scientific,
      ),

      const CalcButtonData(
        'abs',
        'ABS',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'floor',
        'FLOOR',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'ceil',
        'CEIL',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'nPr',
        'NPR',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'nCr',
        'NCR',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'mod',
        'MOD',
        type: CalcButtonType.scientific,
      ),

      const CalcButtonData(
        'GCD',
        'GCD',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'LCM',
        'LCM',
        type: CalcButtonType.scientific,
      ),
      const CalcButtonData(
        'M+',
        'M+',
        type: CalcButtonType.memory,
      ),
      const CalcButtonData(
        'M−',
        'M-',
        type: CalcButtonType.memory,
      ),
      const CalcButtonData(
        'RCL',
        'RCL',
        type: CalcButtonType.memory,
      ),
      const CalcButtonData(
        'MC',
        'MC',
        type: CalcButtonType.memory,
      ),

      const CalcButtonData(
        '(',
        '(',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        ')',
        ')',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        'π',
        'PI',
        type: CalcButtonType.constant,
      ),
      const CalcButtonData(
        'e',
        'E',
        type: CalcButtonType.constant,
      ),
      const CalcButtonData(
        'Ans',
        'ANS',
        type: CalcButtonType.constant,
      ),
      const CalcButtonData(
        'DEL',
        'DEL',
        type: CalcButtonType.danger,
      ),

      const CalcButtonData('7', '7'),
      const CalcButtonData('8', '8'),
      const CalcButtonData('9', '9'),
      const CalcButtonData(
        '÷',
        '/',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '×',
        '*',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '−',
        '-',
        type: CalcButtonType.operator,
      ),

      const CalcButtonData('4', '4'),
      const CalcButtonData('5', '5'),
      const CalcButtonData('6', '6'),
      const CalcButtonData(
        '+',
        '+',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '%',
        '%',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        'EXP',
        'EXP',
        type: CalcButtonType.operator,
      ),

      const CalcButtonData('1', '1'),
      const CalcButtonData('2', '2'),
      const CalcButtonData('3', '3'),
      const CalcButtonData(
        '±',
        'SIGN',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '.',
        '.',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
      ),

      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
        hidden: true,
      ),
      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
        hidden: true,
      ),
      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
        hidden: true,
      ),
      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
        hidden: true,
      ),
      const CalcButtonData(
        '0',
        '0',
        type: CalcButtonType.number,
        hidden: true,
      ),
      const CalcButtonData(
        '=',
        '=',
        type: CalcButtonType.equals,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 6;

        final rows = <List<CalcButtonData>>[];

        for (int i = 0; i < keys.length; i += columns) {
          rows.add(
            keys.sublist(
              i,
              math.min(i + columns, keys.length),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Column(
            children: [
              for (final row in rows)
                Expanded(
                  child: Row(
                    children: [
                      for (final button in row)
                        Expanded(
                          child: button.hidden
                              ? const SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: CalcKey(
                                    data: button,
                                    onPressed: () {
                                      onKey(button.action);
                                    },
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum CalcButtonType {
  number,
  operator,
  scientific,
  function,
  memory,
  constant,
  danger,
  equals,
}

class CalcButtonData {
  final String label;
  final String action;
  final CalcButtonType type;
  final bool hidden;

  const CalcButtonData(
    this.label,
    this.action, {
    this.type = CalcButtonType.number,
    this.hidden = false,
  });
}

class CalcKey extends StatelessWidget {
  final CalcButtonData data;
  final VoidCallback onPressed;

  const CalcKey({
    super.key,
    required this.data,
    required this.onPressed,
  });

  Color get background {
    switch (data.type) {
      case CalcButtonType.number:
        return const Color(0xFF181C21);

      case CalcButtonType.operator:
        return const Color(0xFF20272E);

      case CalcButtonType.scientific:
        return const Color(0xFF171D23);

      case CalcButtonType.function:
        return const Color(0xFF20262D);

      case CalcButtonType.memory:
        return const Color(0xFF1C252B);

      case CalcButtonType.constant:
        return const Color(0xFF18242A);

      case CalcButtonType.danger:
        return const Color(0xFF352124);

      case CalcButtonType.equals:
        return const Color(0xFF314D5A);
    }
  }

  Color get foreground {
    switch (data.type) {
      case CalcButtonType.danger:
        return const Color(0xFFFF9A9A);

      case CalcButtonType.equals:
        return Colors.white;

      case CalcButtonType.operator:
        return const Color(0xFFE6F1F7);

      case CalcButtonType.scientific:
        return const Color(0xFFB9D9E7);

      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withOpacity(0.035),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.label,
              style: TextStyle(
                color: foreground,
                fontSize: data.label.length > 5 ? 13 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   EXPRESSION PARSER
   ============================================================ */

class ExpressionParser {
  final String input;
  final double ans;
  final bool degrees;

  int position = 0;

  ExpressionParser(
    this.input, {
    required this.ans,
    required this.degrees,
  });

  double parse() {
    final value = parseExpression();

    skipSpaces();

    if (position < input.length) {
      throw const FormatException('Unexpected characters');
    }

    return value;
  }

  void skipSpaces() {
    while (
        position < input.length &&
        input.codeUnitAt(position) <= 32) {
      position++;
    }
  }

  bool match(String value) {
    skipSpaces();

    if (input.startsWith(value, position)) {
      position += value.length;
      return true;
    }

    return false;
  }

  bool peek(String value) {
    skipSpaces();
    return input.startsWith(value, position);
  }

  double parseExpression() {
    double value = parseTerm();

    while (true) {
      if (match('+')) {
        value += parseTerm();
      } else if (match('-')) {
        value -= parseTerm();
      } else if (peek('mod')) {
        match('mod');
        value %= parseTerm();
      } else {
        break;
      }
    }

    return value;
  }

  double parseTerm() {
    double value = parsePower();

    while (true) {
      if (match('*')) {
        value *= parsePower();
      } else if (match('/')) {
        final divisor = parsePower();

        if (divisor == 0) {
          throw const FormatException('Division by zero');
        }

        value /= divisor;
      } else if (canStartImplicitMultiplication()) {
        value *= parsePower();
      } else {
        break;
      }
    }

    return value;
  }

  bool canStartImplicitMultiplication() {
    skipSpaces();

    if (position >= input.length) return false;

    final char = input[position];

    return char == '(' ||
        char == 'π' ||
        char == 'e' ||
        char == 'A' ||
        char == 's' ||
        char == 'c' ||
        char == 't' ||
        char == 'l' ||
        char == 'a' ||
        char == 'f' ||
        char == 'g' ||
        char == 'n';
  }

  double parsePower() {
    double value = parseUnary();

    skipSpaces();

    if (match('^')) {
      final exponent = parsePower();
      value = math.pow(value, exponent).toDouble();
    }

    return value;
  }

  double parseUnary() {
    skipSpaces();

    if (match('+')) {
      return parseUnary();
    }

    if (match('-')) {
      return -parseUnary();
    }

    return parsePostfix();
  }

  double parsePostfix() {
    double value = parsePrimary();

    while (true) {
      skipSpaces();

      if (match('!')) {
        value = factorial(value);
      } else if (match('%')) {
        value /= 100;
      } else {
        break;
      }
    }

    return value;
  }

  double parsePrimary() {
    skipSpaces();

    if (position >= input.length) {
      throw const FormatException('Unexpected end');
    }

    if (match('(')) {
      final value = parseExpression();

      if (!match(')')) {
        throw const FormatException('Missing )');
      }

      return value;
    }

    if (isDigit(input[position]) || input[position] == '.') {
      return parseNumber();
    }

    if (input[position] == 'π') {
      position++;
      return math.pi;
    }

    if (input[position] == 'e') {
      position++;

      if (position < input.length &&
          isLetter(input[position])) {
        throw const FormatException('Invalid e');
      }

      return math.e;
    }

    if (input.startsWith('Ans', position)) {
      position += 3;
      return ans;
    }

    if (isLetter(input[position])) {
      final name = parseIdentifier();

      if (name == 'mod') {
        throw const FormatException('mod needs two operands');
      }

      if (!match('(')) {
        throw const FormatException('Function requires (');
      }

      final args = <double>[];

      skipSpaces();

      if (!peek(')')) {
        args.add(parseExpression());

        while (match(',')) {
          args.add(parseExpression());
        }
      }

      if (!match(')')) {
        throw const FormatException('Missing )');
      }

      return evaluateFunction(name, args);
    }

    throw const FormatException('Invalid expression');
  }

  double parseNumber() {
    skipSpaces();

    final start = position;

    bool hasDigits = false;

    while (
        position < input.length &&
        isDigit(input[position])) {
      position++;
      hasDigits = true;
    }

    if (position < input.length &&
        input[position] == '.') {
      position++;

      while (
          position < input.length &&
          isDigit(input[position])) {
        position++;
        hasDigits = true;
      }
    }

    if (!hasDigits) {
      throw const FormatException('Invalid number');
    }

    if (position < input.length &&
        (input[position] == 'E' ||
            input[position] == 'e')) {
      final save = position;

      position++;

      if (position < input.length &&
          (input[position] == '+' ||
              input[position] == '-')) {
        position++;
      }

      final exponentStart = position;

      while (
          position < input.length &&
          isDigit(input[position])) {
        position++;
      }

      if (exponentStart == position) {
        position = save;
      }
    }

    final text = input.substring(start, position);

    final value = double.tryParse(text);

    if (value == null) {
      throw const FormatException('Invalid number');
    }

    return value;
  }

  String parseIdentifier() {
    skipSpaces();

    final start = position;

    while (
        position < input.length &&
        isLetter(input[position])) {
      position++;
    }

    return input.substring(start, position);
  }

  double evaluateFunction(
    String name,
    List<double> args,
  ) {
    if (name == 'sin') {
      requireArgs(name, args, 1);
      return math.sin(toRadians(args[0]));
    }

    if (name == 'cos') {
      requireArgs(name, args, 1);
      return math.cos(toRadians(args[0]));
    }

    if (name == 'tan') {
      requireArgs(name, args, 1);
      final angle = toRadians(args[0]);
      final cosValue = math.cos(angle);

      if (cosValue.abs() < 1e-12) {
        throw const FormatException('Undefined tan');
      }

      return math.tan(angle);
    }

    if (name == 'asin') {
      requireArgs(name, args, 1);
      checkRange(args[0], -1, 1);
      return fromRadians(math.asin(args[0]));
    }

    if (name == 'acos') {
      requireArgs(name, args, 1);
      checkRange(args[0], -1, 1);
      return fromRadians(math.acos(args[0]));
    }

    if (name == 'atan') {
      requireArgs(name, args, 1);
      return fromRadians(math.atan(args[0]));
    }

    if (name == 'sinh') {
      requireArgs(name, args, 1);
      return math.sinh(toRadians(args[0]));
    }

    if (name == 'cosh') {
      requireArgs(name, args, 1);
      return math.cosh(toRadians(args[0]));
    }

    if (name == 'tanh') {
      requireArgs(name, args, 1);
      return math.tanh(toRadians(args[0]));
    }

    if (name == 'asinh') {
      requireArgs(name, args, 1);
      return fromRadians(math.asinh(args[0]));
    }

    if (name == 'acosh') {
      requireArgs(name, args, 1);

      if (args[0] < 1) {
        throw const FormatException('Invalid acosh');
      }

      return fromRadians(math.acosh(args[0]));
    }

    if (name == 'atanh') {
      requireArgs(name, args, 1);

      if (args[0].abs() >= 1) {
        throw const FormatException('Invalid atanh');
      }

      return fromRadians(math.atanh(args[0]));
    }

    if (name == 'sqrt') {
      requireArgs(name, args, 1);

      if (args[0] < 0) {
        throw const FormatException('Invalid sqrt');
      }

      return math.sqrt(args[0]);
    }

    if (name == 'cbrt') {
      requireArgs(name, args, 1);

      final value = args[0];

      if (value >= 0) {
        return math.pow(value, 1 / 3).toDouble();
      }

      return -math.pow(-value, 1 / 3).toDouble();
    }

    if (name == 'log') {
      requireArgs(name, args, 1);

      if (args[0] <= 0) {
        throw const FormatException('Invalid log');
      }

      return math.log(args[0]) / math.ln10;
    }

    if (name == 'ln') {
      requireArgs(name, args, 1);

      if (args[0] <= 0) {
        throw const FormatException('Invalid ln');
      }

      return math.log(args[0]);
    }

    if (name == 'exp') {
      requireArgs(name, args, 1);
      return math.exp(args[0]);
    }

    if (name == 'abs') {
      requireArgs(name, args, 1);
      return args[0].abs();
    }

    if (name == 'floor') {
      requireArgs(name, args, 1);
      return args[0].floorToDouble();
    }

    if (name == 'ceil') {
      requireArgs(name, args, 1);
      return args[0].ceilToDouble();
    }

    if (name == 'nPr') {
      requireArgs(name, args, 2);

      final n = integerValue(args[0]);
      final r = integerValue(args[1]);

      if (r < 0 || n < 0 || r > n) {
        throw const FormatException('Invalid nPr');
      }

      double value = 1;

      for (int i = 0; i < r; i++) {
        value *= n - i;
      }

      return value;
    }

    if (name == 'nCr') {
      requireArgs(name, args, 2);

      final n = integerValue(args[0]);
      final r = integerValue(args[1]);

      if (r < 0 || n < 0 || r > n) {
        throw const FormatException('Invalid nCr');
      }

      final k = math.min(r, n - r);

      double value = 1;

      for (int i = 1; i <= k; i++) {
        value *= (n - k + i) / i;
      }

      return value;
    }

    if (name == 'gcd') {
      requireArgs(name, args, 2);

      int a = integerValue(args[0]).abs();
      int b = integerValue(args[1]).abs();

      while (b != 0) {
        final temp = a % b;
        a = b;
        b = temp;
      }

      return a.toDouble();
    }

    if (name == 'lcm') {
      requireArgs(name, args, 2);

      final a = integerValue(args[0]).abs();
      final b = integerValue(args[1]).abs();

      if (a == 0 || b == 0) return 0;

      int x = a;
      int y = b;

      while (y != 0) {
        final temp = x % y;
        x = y;
        y = temp;
      }

      final gcd = x;

      return ((a ~/ gcd) * b).toDouble();
    }

    throw FormatException('Unknown function: $name');
  }

  double toRadians(double value) {
    if (!degrees) return value;

    return value * math.pi / 180;
  }

  double fromRadians(double value) {
    if (!degrees) return value;

    return value * 180 / math.pi;
  }

  static void requireArgs(
    String name,
    List<double> args,
    int count,
  ) {
    if (args.length != count) {
      throw FormatException(
        '$name requires $count argument(s)',
      );
    }
  }

  static void checkRange(
    double value,
    double min,
    double max,
  ) {
    if (value < min || value > max) {
      throw const FormatException('Out of range');
    }
  }

  static int integerValue(double value) {
    if (!value.isFinite ||
        value != value.roundToDouble()) {
      throw const FormatException(
        'Integer required',
      );
    }

    return value.toInt();
  }

  static double factorial(double value) {
    if (!value.isFinite ||
        value < 0 ||
        value != value.roundToDouble()) {
      throw const FormatException(
        'Factorial requires a non-negative integer',
      );
    }

    final n = value.toInt();

    if (n > 170) {
      throw const FormatException(
        'Number too large',
      );
    }

    double result = 1;

    for (int i = 2; i <= n; i++) {
      result *= i;
    }

    return result;
  }

  static bool isDigit(String value) {
    if (value.isEmpty) return false;

    final code = value.codeUnitAt(0);

    return code >= 48 && code <= 57;
  }

  static bool isLetter(String value) {
    if (value.isEmpty) return false;

    final code = value.codeUnitAt(0);

    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122);
  }
}