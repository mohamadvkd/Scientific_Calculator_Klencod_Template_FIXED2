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

enum CalcButtonType {
  number,
  operator,
  function,
  action,
  memory,
}

class CalcButtonData {
  final String label;
  final String action;
  final CalcButtonType type;

  const CalcButtonData(
    this.label,
    this.action, {
    this.type = CalcButtonType.number,
  });
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

  final ScrollController _displayScrollController = ScrollController();

  @override
  void dispose() {
    _displayScrollController.dispose();
    super.dispose();
  }

  void insert(String value) {
    if (expression.length >= maxExpressionLength) return;

    setState(() {
      expression += value;

      if (expression.length > maxExpressionLength) {
        expression = expression.substring(0, maxExpressionLength);
      }
    });

    _scrollDisplayToEnd();
  }

  void _scrollDisplayToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_displayScrollController.hasClients) {
        _displayScrollController.animateTo(
          _displayScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void backspace() {
    if (expression.isEmpty) return;

    setState(() {
      expression = expression.substring(0, expression.length - 1);
    });
  }

  void clearAll() {
    setState(() {
      expression = '';
      result = '0';
    });
  }

  void evaluateExpression() {
    if (expression.trim().isEmpty) return;

    try {
      // The display uses modern calculator symbols:
      // × ÷ −
      // Internally the parser uses:
      // * / -
      final normalized = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');

      final parser = ExpressionParser(
        normalized,
        ans: ans,
        degrees: degrees,
      );

      final value = parser.parse();

      if (value.isNaN || value.isInfinite) {
        throw const FormatException('Invalid result');
      }

      ans = value;

      final formatted = formatNumber(value);

      setState(() {
        result = formatted;

        history.insert(
          0,
          '$expression = $formatted',
        );

        if (history.length > 50) {
          history.removeLast();
        }
      });
    } catch (_) {
      setState(() {
        result = 'Error';
      });
    }
  }

  String formatNumber(double value) {
    if (value.abs() < 1e-12) {
      value = 0;
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final abs = value.abs();

    if (abs >= 1e12 || (abs > 0 && abs < 1e-10)) {
      return value
          .toStringAsExponential(10)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }

    String text = value.toStringAsPrecision(14);

    if (text.contains('e')) {
      return text;
    }

    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');

    return text;
  }

  void handleKey(String key) {
    switch (key) {
      case 'AC':
        clearAll();
        break;

      case '⌫':
        backspace();
        break;

      case '=':
        evaluateExpression();
        break;

      case 'SHIFT':
        setState(() {
          shift = !shift;
        });
        break;

      case '2nd':
        setState(() {
          second = !second;
        });
        break;

      case 'DEG':
        setState(() {
          degrees = true;
        });
        break;

      case 'RAD':
        setState(() {
          degrees = false;
        });
        break;

      case 'M+':
        _memoryAdd();
        break;

      case 'M-':
        _memorySubtract();
        break;

      case 'RCL':
        insert(formatNumber(memory));
        break;

      case 'MC':
        setState(() {
          memory = 0;
        });
        break;

      case 'COPY':
        Clipboard.setData(
          ClipboardData(
            text: result,
          ),
        );
        break;

      case 'HISTORY':
        _showHistory();
        break;

      case 'ANS':
        insert('Ans');
        break;

      case 'π':
        insert('π');
        break;

      case 'e':
        insert('e');
        break;

      case 'EXP':
        insert('E');
        break;

      case 'x²':
        insert('^2');
        break;

      case 'x³':
        insert('^3');
        break;

      case 'xʸ':
        insert('^');
        break;

      case '√':
        insert('sqrt(');
        break;

      case '∛':
        insert('cbrt(');
        break;

      case 'log':
        insert('log(');
        break;

      case 'ln':
        insert('ln(');
        break;

      case 'sin':
        insert('sin(');
        break;

      case 'cos':
        insert('cos(');
        break;

      case 'tan':
        insert('tan(');
        break;

      case 'asin':
        insert('asin(');
        break;

      case 'acos':
        insert('acos(');
        break;

      case 'atan':
        insert('atan(');
        break;

      case 'sinh':
        insert('sinh(');
        break;

      case 'cosh':
        insert('cosh(');
        break;

      case 'tanh':
        insert('tanh(');
        break;

      case 'asinh':
        insert('asinh(');
        break;

      case 'acosh':
        insert('acosh(');
        break;

      case 'atanh':
        insert('atanh(');
        break;

      case 'abs':
        insert('abs(');
        break;

      case 'floor':
        insert('floor(');
        break;

      case 'ceil':
        insert('ceil(');
        break;

      case 'fact':
        insert('!');
        break;

      case 'nPr':
        insert('nPr(');
        break;

      case 'nCr':
        insert('nCr(');
        break;

      case 'gcd':
        insert('gcd(');
        break;

      case 'lcm':
        insert('lcm(');
        break;

      case 'mod':
        insert('mod(');
        break;

      case '%':
        insert('%');
        break;

      default:
        insert(key);
    }
  }

  void _memoryAdd() {
    final value = _currentNumericValue();
    if (value == null) return;

    setState(() {
      memory += value;
    });
  }

  void _memorySubtract() {
    final value = _currentNumericValue();
    if (value == null) return;

    setState(() {
      memory -= value;
    });
  }

  double? _currentNumericValue() {
    try {
      final source = expression.isNotEmpty ? expression : result;

      final normalized = source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');

      return ExpressionParser(
        normalized,
        ans: ans,
        degrees: degrees,
      ).parse();
    } catch (_) {
      return null;
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text(
                            'No calculations yet',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: history.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                history[index],
                                textAlign: TextAlign.right,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                final item = history[index];
                                final parts = item.split(' = ');

                                if (parts.isNotEmpty) {
                                  setState(() {
                                    expression = parts.first;
                                    if (parts.length > 1) {
                                      result = parts[1];
                                    }
                                  });
                                }
                              },
                            );
                          },
                        ),
                ),
                if (history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            history.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear History'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CalcButtonData> get buttons {
    final List<CalcButtonData> list = [];

    list.addAll([
      const CalcButtonData(
        'SHIFT',
        'SHIFT',
        type: CalcButtonType.action,
      ),
      const CalcButtonData(
        '2nd',
        '2nd',
        type: CalcButtonType.action,
      ),
      CalcButtonData(
        degrees ? 'DEG' : 'RAD',
        degrees ? 'RAD' : 'DEG',
        type: CalcButtonType.action,
      ),
      const CalcButtonData(
        'HIST',
        'HISTORY',
        type: CalcButtonType.action,
      ),
      const CalcButtonData(
        '⌫',
        '⌫',
        type: CalcButtonType.action,
      ),
      const CalcButtonData(
        'AC',
        'AC',
        type: CalcButtonType.action,
      ),
    ]);

    list.addAll([
      const CalcButtonData(
        'sin',
        'sin',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'cos',
        'cos',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'tan',
        'tan',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'log',
        'log',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'ln',
        'ln',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        '√',
        '√',
        type: CalcButtonType.function,
      ),
    ]);

    list.addAll([
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
        'π',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'e',
        'e',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'x²',
        'x²',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'xʸ',
        'xʸ',
        type: CalcButtonType.function,
      ),
    ]);

    list.addAll([
      const CalcButtonData('7', '7'),
      const CalcButtonData('8', '8'),
      const CalcButtonData('9', '9'),
      const CalcButtonData(
        '÷',
        '÷',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        'mod',
        'mod',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        '%',
        '%',
        type: CalcButtonType.operator,
      ),
    ]);

    list.addAll([
      const CalcButtonData('4', '4'),
      const CalcButtonData('5', '5'),
      const CalcButtonData('6', '6'),
      const CalcButtonData(
        '×',
        '×',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '−',
        '−',
        type: CalcButtonType.operator,
      ),
      const CalcButtonData(
        '+',
        '+',
        type: CalcButtonType.operator,
      ),
    ]);

    list.addAll([
      const CalcButtonData('1', '1'),
      const CalcButtonData('2', '2'),
      const CalcButtonData('3', '3'),
      const CalcButtonData(
        'Ans',
        'ANS',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        'EXP',
        'EXP',
        type: CalcButtonType.function,
      ),
      const CalcButtonData(
        '=',
        '=',
        type: CalcButtonType.operator,
      ),
    ]);

    list.addAll([
      const CalcButtonData('0', '0'),
      const CalcButtonData('.', '.'),
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
    ]);

    return list;
  }

  String get secondaryFunctionLabel {
    if (!shift && !second) {
      return 'Scientific';
    }

    if (shift && !second) {
      return 'Inverse / Hyperbolic';
    }

    if (second) {
      return 'Advanced';
    }

    return 'Scientific';
  }

  List<CalcButtonData> get scientificButtons {
    if (second) {
      return const [
        CalcButtonData(
          'asin',
          'asin',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'acos',
          'acos',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'atan',
          'atan',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'abs',
          'abs',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'floor',
          'floor',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'ceil',
          'ceil',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'fact',
          'fact',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'nPr',
          'nPr',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'nCr',
          'nCr',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'gcd',
          'gcd',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'lcm',
          'lcm',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'cbrt',
          'cbrt(',
          type: CalcButtonType.function,
        ),
      ];
    }

    if (shift) {
      return const [
        CalcButtonData(
          'sinh',
          'sinh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'cosh',
          'cosh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'tanh',
          'tanh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'asinh',
          'asinh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'acosh',
          'acosh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'atanh',
          'atanh',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          '∛',
          '∛',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'x³',
          'x³',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'exp',
          'exp(',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'floor',
          'floor',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'ceil',
          'ceil',
          type: CalcButtonType.function,
        ),
        CalcButtonData(
          'abs',
          'abs',
          type: CalcButtonType.function,
        ),
      ];
    }

    return const [
      CalcButtonData(
        'sin',
        'sin',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'cos',
        'cos',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'tan',
        'tan',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'log',
        'log',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'ln',
        'ln',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        '√',
        '√',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'x²',
        'x²',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'xʸ',
        'xʸ',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'π',
        'π',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'e',
        'e',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'nPr',
        'nPr',
        type: CalcButtonType.function,
      ),
      CalcButtonData(
        'nCr',
        'nCr',
        type: CalcButtonType.function,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildDisplay(),
            _buildScientificPanel(),
            Expanded(
              child: _buildKeypad(screenWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Scientific Calculator',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'M: ${formatNumber(memory)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Copy result',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: result),
              );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12151A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 42,
            child: SingleChildScrollView(
              controller: _displayScrollController,
              scrollDirection: Axis.horizontal,
              reverse: false,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  expression.isEmpty ? '0' : expression,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                result,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificPanel() {
    final items = scientificButtons;

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFF101318),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              child: Text(
                secondaryFunctionLabel,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final button = items[index];

                return _buildButton(
                  button,
                  compact: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(double width) {
    final items = buttons;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 1.12,
        ),
        itemBuilder: (context, index) {
          return _buildButton(items[index]);
        },
      ),
    );
  }

  Widget _buildButton(
    CalcButtonData button, {
    bool compact = false,
  }) {
    final bool isEquals = button.action == '=';
    final bool isOperator =
        button.type == CalcButtonType.operator;

    Color background;

    if (isEquals) {
      background = const Color(0xFF3F78FF);
    } else if (isOperator) {
      background = const Color(0xFF252A32);
    } else if (button.type == CalcButtonType.function) {
      background = const Color(0xFF191D23);
    } else if (button.type == CalcButtonType.memory) {
      background = const Color(0xFF171B20);
    } else {
      background = const Color(0xFF20242A);
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(
        compact ? 10 : 14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          compact ? 10 : 14,
        ),
        onTap: () => handleKey(button.action),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              button.label,
              style: TextStyle(
                fontSize: compact ? 13 : 17,
                fontWeight: isOperator || isEquals
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EXPRESSION PARSER
// ============================================================

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
    position = 0;

    final value = parseExpression();

    skipSpaces();

    if (position < input.length) {
      throw const FormatException('Unexpected input');
    }

    return value;
  }

  void skipSpaces() {
    while (position < input.length &&
        input[position].trim().isEmpty) {
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
          throw const FormatException(
            'Division by zero',
          );
        }

        value /= divisor;
      } else if (match('%')) {
        value %= parsePower();
      } else if (_startsImplicitMultiplication()) {
        value *= parsePower();
      } else {
        break;
      }
    }

    return value;
  }

  bool _startsImplicitMultiplication() {
    skipSpaces();

    if (position >= input.length) {
      return false;
    }

    final c = input[position];

    return c == '(' ||
        c == 'π' ||
        c == 'e' ||
        c == 'A' ||
        c == 's' ||
        c == 'c' ||
        c == 't' ||
        c == 'l' ||
        c == 'a' ||
        c == 'f' ||
        c == 'n' ||
        c == 'g';
  }

  double parsePower() {
    double value = parseUnary();

    if (match('^')) {
      final exponent = parsePower();
      value = math.pow(value, exponent).toDouble();
    }

    return value;
  }

  double parseUnary() {
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
      if (match('!')) {
        value = factorial(value);
      } else {
        break;
      }
    }

    return value;
  }

  double parsePrimary() {
    skipSpaces();

    if (position >= input.length) {
      throw const FormatException('Expected value');
    }

    if (match('(')) {
      final value = parseExpression();

      if (!match(')')) {
        throw const FormatException(
          'Missing closing parenthesis',
        );
      }

      return value;
    }

    if (peek('π')) {
      position++;
      return math.pi;
    }

    if (peek('Ans')) {
      position += 3;
      return ans;
    }

    if (peek('e')) {
      // Do not treat e inside a number as Euler's constant.
      if (position == 0 ||
          !RegExp(r'[0-9.]').hasMatch(
            input[position - 1],
          )) {
        position++;
        return math.e;
      }
    }

    if (_isLetterAtCurrentPosition()) {
      return parseFunction();
    }

    return parseNumber();
  }

  bool _isLetterAtCurrentPosition() {
    if (position >= input.length) return false;

    final c = input[position];

    return RegExp(r'[A-Za-z]').hasMatch(c);
  }

  double parseNumber() {
    skipSpaces();

    final start = position;

    bool hasDigits = false;
    bool hasDot = false;

    while (position < input.length) {
      final c = input[position];

      if (_isDigit(c)) {
        hasDigits = true;
        position++;
      } else if (c == '.' && !hasDot) {
        hasDot = true;
        position++;
      } else {
        break;
      }
    }

    if (!hasDigits) {
      throw const FormatException(
        'Expected number',
      );
    }

    // Scientific notation: 1E5 or 1e-5
    if (position < input.length &&
        (input[position] == 'E' ||
            input[position] == 'e')) {
      final ePosition = position;
      position++;

      if (position < input.length &&
          (input[position] == '+' ||
              input[position] == '-')) {
        position++;
      }

      final exponentStart = position;

      while (position < input.length &&
          _isDigit(input[position])) {
        position++;
      }

      if (position == exponentStart) {
        position = ePosition;
      }
    }

    final text = input.substring(start, position);

    final value = double.tryParse(text);

    if (value == null) {
      throw const FormatException(
        'Invalid number',
      );
    }

    return value;
  }

  bool _isDigit(String c) {
    return c.codeUnitAt(0) >= 48 &&
        c.codeUnitAt(0) <= 57;
  }

  double parseFunction() {
    skipSpaces();

    final start = position;

    while (position < input.length &&
        RegExp(r'[A-Za-z]').hasMatch(input[position])) {
      position++;
    }

    final name = input.substring(start, position);

    if (name == 'Ans') {
      return ans;
    }

    if (!match('(')) {
      throw FormatException(
        'Expected ( after $name',
      );
    }

    final List<double> args = [];

    skipSpaces();

    if (!peek(')')) {
      while (true) {
        args.add(parseExpression());

        skipSpaces();

        if (match(',')) {
          continue;
        }

        break;
      }
    }

    if (!match(')')) {
      throw const FormatException(
        'Missing )',
      );
    }

    return evaluateFunction(name, args);
  }

  double evaluateFunction(
    String name,
    List<double> args,
  ) {
    requireArgs(name, args, 1);

    switch (name) {
      case 'sin':
        return math.sin(toRadians(args[0]));

      case 'cos':
        return math.cos(toRadians(args[0]));

      case 'tan':
        return math.tan(toRadians(args[0]));

      case 'asin':
        return fromRadians(math.asin(args[0]));

      case 'acos':
        return fromRadians(math.acos(args[0]));

      case 'atan':
        return fromRadians(math.atan(args[0]));

      // Flutter 3.16.0 does not provide math.sinh/cosh/tanh.
      // They are implemented using their mathematical formulas.
      case 'sinh':
        return (math.exp(args[0]) -
                math.exp(-args[0])) /
            2;

      case 'cosh':
        return (math.exp(args[0]) +
                math.exp(-args[0])) /
            2;

      case 'tanh':
        final ex = math.exp(args[0]);
        final enx = math.exp(-args[0]);

        return (ex - enx) /
            (ex + enx);

      // Inverse hyperbolic functions.
      case 'asinh':
        final x = args[0];

        return math.log(
          x + math.sqrt(x * x + 1),
        );

      case 'acosh':
        final x = args[0];

        if (x < 1) {
          throw const FormatException(
            'Invalid acosh',
          );
        }

        return math.log(
          x + math.sqrt(x * x - 1),
        );

      case 'atanh':
        final x = args[0];

        if (x.abs() >= 1) {
          throw const FormatException(
            'Invalid atanh',
          );
        }

        return 0.5 *
            math.log(
              (1 + x) / (1 - x),
            );

      case 'sqrt':
        if (args[0] < 0) {
          throw const FormatException(
            'Invalid sqrt',
          );
        }

        return math.sqrt(args[0]);

      case 'cbrt':
        return cubeRoot(args[0]);

      case 'log':
        if (args[0] <= 0) {
          throw const FormatException(
            'Invalid log',
          );
        }

        return math.log(args[0]) / math.ln10;

      case 'ln':
        if (args[0] <= 0) {
          throw const FormatException(
            'Invalid ln',
          );
        }

        return math.log(args[0]);

      case 'exp':
        return math.exp(args[0]);

      case 'abs':
        return args[0].abs();

      case 'floor':
        return args[0].floorToDouble();

      case 'ceil':
        return args[0].ceilToDouble();

      case 'nPr':
        requireArgs('nPr', args, 2);
        return permutation(
          args[0],
          args[1],
        );

      case 'nCr':
        requireArgs('nCr', args, 2);
        return combination(
          args[0],
          args[1],
        );

      case 'gcd':
        requireArgs('gcd', args, 2);
        return gcd(
          args[0],
          args[1],
        ).toDouble();

      case 'lcm':
        requireArgs('lcm', args, 2);
        return lcm(
          args[0],
          args[1],
        ).toDouble();

      case 'mod':
        requireArgs('mod', args, 2);

        if (args[1] == 0) {
          throw const FormatException(
            'Division by zero',
          );
        }

        return args[0] % args[1];

      default:
        throw FormatException(
          'Unknown function: $name',
        );
    }
  }

  void requireArgs(
    String name,
    List<double> args,
    int minimum,
  ) {
    if (args.length < minimum) {
      throw FormatException(
        '$name requires arguments',
      );
    }
  }

  double toRadians(double value) {
    if (!degrees) return value;

    return value * math.pi / 180;
  }

  double fromRadians(double value) {
    if (!degrees) return value;

    return value * 180 / math.pi;
  }

  double cubeRoot(double x) {
    if (x >= 0) {
      return math.pow(x, 1 / 3).toDouble();
    }

    return -math.pow(-x, 1 / 3).toDouble();
  }

  double factorial(double value) {
    if (value < 0 ||
        value != value.roundToDouble()) {
      throw const FormatException(
        'Invalid factorial',
      );
    }

    if (value > 170) {
      throw const FormatException(
        'Factorial too large',
      );
    }

    double result = 1;

    for (int i = 2; i <= value.toInt(); i++) {
      result *= i;
    }

    return result;
  }

  double permutation(
    double nValue,
    double rValue,
  ) {
    final n = nValue.round();
    final r = rValue.round();

    if (nValue != n ||
        rValue != r ||
        n < 0 ||
        r < 0 ||
        r > n) {
      throw const FormatException(
        'Invalid nPr',
      );
    }

    double result = 1;

    for (int i = 0; i < r; i++) {
      result *= n - i;
    }

    return result;
  }

  double combination(
    double nValue,
    double rValue,
  ) {
    final n = nValue.round();
    final r = rValue.round();

    if (nValue != n ||
        rValue != r ||
        n < 0 ||
        r < 0 ||
        r > n) {
      throw const FormatException(
        'Invalid nCr',
      );
    }

    final k = math.min(r, n - r);

    double result = 1;

    for (int i = 1; i <= k; i++) {
      result *= (n - k + i);
      result /= i;
    }

    return result;
  }

  int gcd(
    double aValue,
    double bValue,
  ) {
    int a = aValue.round().abs();
    int b = bValue.round().abs();

    while (b != 0) {
      final temp = a % b;
      a = b;
      b = temp;
    }

    return a;
  }

  int lcm(
    double aValue,
    double bValue,
  ) {
    final a = aValue.round().abs();
    final b = bValue.round().abs();

    if (a == 0 || b == 0) {
      return 0;
    }

    return (a ~/ gcd(a.toDouble(), b.toDouble())) * b;
  }
}