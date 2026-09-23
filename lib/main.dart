import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'الحاسبة العلمية',
        theme: ThemeData.dark(useMaterial3: true),
        home: const CalculatorPage(),
      );
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String exp = '';
  String answerText = '0';
  String previous = '';

  bool shift = false;
  bool degrees = true;

  double ans = 0;
  double memory = 0;

  final history = <String>[];

  void add(String s) {
    setState(() {
      exp += s;
      if (exp.length > 44) {
        exp = exp.substring(0, 44);
      }
    });
  }

  void press(String s) {
    switch (s) {
      case 'AC':
        setState(() {
          exp = '';
          answerText = '0';
          previous = '';
        });
        return;

      case 'DEL':
        if (exp.isNotEmpty) {
          setState(() {
            exp = exp.substring(0, exp.length - 1);
          });
        }
        return;

      case '=':
        calculate();
        return;

      case 'SHIFT':
        setState(() {
          shift = !shift;
        });
        return;

      case 'MODE':
        setState(() {
          degrees = !degrees;
        });
        return;

      case 'RAD':
        setState(() {
          degrees = false;
        });
        return;

      case 'DEG':
        setState(() {
          degrees = true;
        });
        return;

      case '×':
        add('*');
        return;

      case '÷':
        add('/');
        return;

      case '−':
        add('-');
        return;

      case '+':
      case '(':
      case ')':
      case '.':
        add(s);
        return;

      case 'π':
        add('pi');
        return;

      case 'e':
        add('e');
        return;

      case 'Ans':
        add('Ans');
        return;

      case 'x²':
        add('^2');
        return;

      case 'x³':
        add('^3');
        return;

      case 'xʸ':
        add('^');
        return;

      case 'x⁻¹':
        add('^-1');
        return;

      case '√':
        add('sqrt(');
        return;

      case 'Log':
        add('log(');
        return;

      case 'Ln':
        add('ln(');
        return;

      case 'Sin':
        add(shift ? 'asin(' : 'sin(');
        return;

      case 'Cos':
        add(shift ? 'acos(' : 'cos(');
        return;

      case 'Tan':
        add(shift ? 'atan(' : 'tan(');
        return;

      case '(-)':
        add('-');
        return;

      case '%':
        add('%');
        return;

      case 'mod':
        add('mod');
        return;

      case 'nPr':
        add('P');
        return;

      case 'nCr':
        add('C');
        return;

      case 'M+':
        memoryChange(true);
        return;

      case 'M−':
        memoryChange(false);
        return;

      case 'RCL':
        add(format(memory));
        return;

      case 'History':
        showHistory();
        return;

      case 'COPY':
        setState(() {
          exp = answerText;
        });
        return;

      case 'EXP':
        add('e');
        return;
    }

    if (RegExp(r'^\d$').hasMatch(s)) {
      add(s);
    }
  }

  void memoryChange(bool plus) {
    try {
      final v = ExpressionParser(
        exp.isEmpty ? 'Ans' : exp,
        degrees,
        ans,
      ).parse();

      setState(() {
        memory += plus ? v : -v;
      });
    } catch (_) {}
  }

  void calculate() {
    if (exp.trim().isEmpty) return;

    try {
      final v = ExpressionParser(exp, degrees, ans).parse();

      if (!v.isFinite) {
        throw const FormatException();
      }

      final f = format(v);

      setState(() {
        previous = exp;
        answerText = f;
        ans = v;

        history.insert(0, '$exp = $f');

        if (history.length > 40) {
          history.removeLast();
        }

        exp = f;
      });
    } catch (_) {
      setState(() {
        answerText = 'Error';
      });
    }
  }

  void showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff101319),
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text('No calculations yet'),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(
                            history[i],
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            final p = history[i].split(' = ');

                            if (p.isNotEmpty) {
                              setState(() {
                                exp = p.first;
                              });
                            }

                            Navigator.pop(context);
                          },
                        ),
                      ),
              ),
              TextButton(
                onPressed: () {
                  setState(history.clear);
                  Navigator.pop(context);
                },
                child: const Text('Clear history'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget key(
    String label, {
    String? sub,
    bool orange = false,
  }) {
    return CalcKey(
      label: label,
      sub: sub,
      orange: orange,
      onTap: () => press(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[
      [
        key('SHIFT', orange: true),
        key('ALPHA'),
        key('←'),
        key('→'),
        key('MODE'),
        key('2nd'),
      ],
      [
        key('CALC', sub: 'SOLVE ='),
        key('∫dx', sub: 'd/dx'),
        key('▲'),
        key('▼'),
        key('x⁻¹', sub: 'x!'),
        key('Logₐx', sub: 'Σ  Π'),
      ],
      [
        key('÷', sub: 'mod  ÷R'),
        key('√', sub: '³√□'),
        key('x²', sub: 'x³'),
        key('xʸ', sub: '□√□'),
        key('Log', sub: '10ˣ'),
        key('Ln', sub: 'eˣ'),
      ],
      [
        key('(-)', sub: '∠  a'),
        key("° ' ''", sub: 'FACT  b'),
        key('hyp', sub: 'Abs  c'),
        key('Sin', sub: 'Sin⁻¹  d'),
        key('Cos', sub: 'Cos⁻¹  e'),
        key('Tan', sub: 'Tan⁻¹  f'),
      ],
      [
        key('RCL', sub: 'STO'),
        key('ENG', sub: 'CLRV'),
        key('(', sub: 'i'),
        key(')', sub: 'Cot'),
        key('S↔D', sub: '%'),
        key('M+', sub: 'M−'),
      ],
      [
        key('7', sub: 'CONST'),
        key('8', sub: 'CONV'),
        key('9', sub: 'Limit  ∞'),
        key('DEL', orange: true),
        key('AC', orange: true),
        key('History', sub: 'PreAns'),
      ],
      [
        key('4', sub: 'MATRIX'),
        key('5', sub: 'VECTOR'),
        key('6', sub: 'HELP'),
        key('×', sub: 'nPr  GCD'),
        key('÷', sub: 'nCr  LCM'),
        key('Ans'),
      ],
      [
        key('1', sub: 'STAT'),
        key('2', sub: 'CMPLX'),
        key('3', sub: 'DISTR'),
        key('+', sub: 'Pol  Ceil'),
        key('−', sub: 'Rec  Floor'),
        key('π', sub: 'e'),
      ],
      [
        key('0', sub: 'COPY'),
        key('.', sub: 'PASTE'),
        key('EXP', sub: 'Ran#  RanInt'),
        key('Ans', sub: 'PreAns'),
        key('=', sub: 'History'),
        key('M+', sub: 'M−'),
      ],
    ];

    return Scaffold(
      backgroundColor: const Color(0xff080a0e),
      body: SafeArea(
        child: Column(
          children: [
            const FakeStatusBar(),

            TopBar(
              degrees: degrees,
              onMenu: showHistory,
              onMode: () {
                setState(() {
                  degrees = !degrees;
                });
              },
            ),

            CalculatorDisplay(
              expression: exp,
              previous: previous,
              result: answerText,
              degrees: degrees,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 1, 4, 3),
                child: Column(
                  children: rows
                      .map(
                        (r) => Expanded(
                          child: Row(
                            children: r
                                .map(
                                  (w) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: w,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            const BottomNav(),
          ],
        ),
      ),
    );
  }
}

class FakeStatusBar extends StatelessWidget {
  const FakeStatusBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        color: const Color(0xff06080b),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: const Row(
          children: [
            Icon(Icons.battery_full, size: 16),
            SizedBox(width: 5),
            Text(
              '76',
              style: TextStyle(fontSize: 10),
            ),
            Spacer(),
            Text(
              '4G   Vo LTE   Wi-Fi   0.0 KB/s',
              style: TextStyle(fontSize: 10),
            ),
            SizedBox(width: 10),
            Text(
              '12:48 ص',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
}

class TopBar extends StatelessWidget {
  final bool degrees;
  final VoidCallback onMenu;
  final VoidCallback onMode;

  const TopBar({
    super.key,
    required this.degrees,
    required this.onMenu,
    required this.onMode,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        color: const Color(0xff11151a),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.tune, size: 30),
            ),
            const Text(
              '◆',
              style: TextStyle(
                color: Color(0xff18a8ff),
                fontSize: 27,
              ),
            ),
            const SizedBox(width: 13),
            const Text(
              'E=mc²',
              style: TextStyle(
                color: Color(0xffc56bff),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            CircleTop(
              text: '−',
              onTap: () {},
            ),
            const SizedBox(width: 6),
            CircleTop(
              text: '+',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            Text(
              degrees ? 'DEG' : 'RAD',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'NORM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'M',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
            const Text(
              'MATH',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'DECI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onMode,
              icon: const Icon(
                Icons.arrow_forward,
                size: 30,
              ),
            ),
          ],
        ),
      );
}

class CircleTop extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CircleTop({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white70,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 25,
              ),
            ),
          ),
        ),
      );
}

class CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String previous;
  final String result;
  final bool degrees;

  const CalculatorDisplay({
    super.key,
    required this.expression,
    required this.previous,
    required this.result,
    required this.degrees,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        height: MediaQuery.of(context).size.height * .215,
        padding: const EdgeInsets.fromLTRB(13, 10, 14, 7),
        decoration: BoxDecoration(
          color: const Color(0xffdce8e9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      expression.isEmpty ? '0' : expression,
                      style: const TextStyle(
                        color: Color(0xff172c89),
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                Text(
                  degrees ? 'DEG' : 'RAD',
                  style: const TextStyle(
                    color: Color(0xff3c4e8e),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (previous.isNotEmpty)
              Text(
                previous,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xff30468e),
                  fontSize: 13,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  '[',
                  style: TextStyle(
                    color: Color(0xff172c89),
                    fontSize: 48,
                  ),
                ),
                Flexible(
                  child: Text(
                    result,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xff172c89),
                      fontSize: 34,
                    ),
                  ),
                ),
                const Text(
                  ']',
                  style: TextStyle(
                    color: Color(0xff172c89),
                    fontSize: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class CalcKey extends StatelessWidget {
  final String label;
  final String? sub;
  final bool orange;
  final VoidCallback onTap;

  const CalcKey({
    super.key,
    required this.label,
    this.sub,
    this.orange = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: orange
                  ? const Color(0xffff9b3d)
                  : const Color(0xff303238),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black87,
                width: 1.1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: orange ? Colors.black : Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (sub != null)
                  Positioned(
                    top: 1,
                    left: 2,
                    right: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        sub!,
                        style: const TextStyle(
                          color: Color(0xffffdf00),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
} // ← هذا القوس كان ناقصاً

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 39,
        color: const Color(0xff06080b),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.menu, size: 26),
            Icon(Icons.circle_outlined, size: 26),
            Icon(Icons.undo, size: 26),
          ],
        ),
      );
}

String format(double v) {
  if (v.abs() < 1e-12) {
    v = 0;
  }

  if ((v - v.roundToDouble()).abs() < 1e-10 && v.abs() < 1e15) {
    return v.toStringAsFixed(0);
  }

  if (v.abs() >= 1e12 || v.abs() < 1e-8) {
    return v
        .toStringAsExponential(8)
        .replaceFirst(RegExp(r'0+e'), 'e');
  }

  return v
      .toStringAsFixed(10)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class ExpressionParser {
  final String source;
  final bool degrees;
  final double ans;

  late final List<String> t;
  int p = 0;

  ExpressionParser(
    this.source,
    this.degrees,
    this.ans,
  ) {
    t = tokenize(
      source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-'),
    );
  }

  List<String> tokenize(String s) {
    final out = <String>[];
    int i = 0;

    while (i < s.length) {
      final c = s[i];

      if (c.trim().isEmpty) {
        i++;
        continue;
      }

      if ('()+-*/^%,!'.contains(c)) {
        out.add(c);
        i++;
        continue;
      }

      if (c == 'π') {
        out.add('pi');
        i++;
        continue;
      }

      if (c == '√') {
        out.add('sqrt');
        i++;
        continue;
      }

      if (c == 'P' || c == 'C') {
        out.add(c);
        i++;
        continue;
      }

      if (RegExp(r'[0-9.]').hasMatch(c)) {
        int j = i + 1;

        while (
            j < s.length &&
            RegExp(r'[0-9.]').hasMatch(s[j])) {
          j++;
        }

        if (j < s.length &&
            (s[j] == 'e' || s[j] == 'E')) {
          int k = j + 1;

          if (k < s.length &&
              (s[k] == '+' || s[k] == '-')) {
            k++;
          }

          final start = k;

          while (
              k < s.length &&
              RegExp(r'[0-9]').hasMatch(s[k])) {
            k++;
          }

          if (k > start) {
            j = k;
          }
        }

        out.add(s.substring(i, j));
        i = j;
        continue;
      }

      if (RegExp(r'[A-Za-z]').hasMatch(c)) {
        int j = i + 1;

        while (
            j < s.length &&
            RegExp(r'[A-Za-z]').hasMatch(s[j])) {
          j++;
        }

        out.add(s.substring(i, j));
        i = j;
        continue;
      }

      throw const FormatException();
    }

    return out;
  }

  bool has(String x) {
    return p < t.length && t[p] == x;
  }

  String take() {
    if (p >= t.length) {
      throw const FormatException();
    }

    return t[p++];
  }

  double parse() {
    if (t.isEmpty) {
      throw const FormatException();
    }

    final v = addSub();

    if (p != t.length) {
      throw const FormatException();
    }

    return v;
  }

  double addSub() {
    var v = mul();

    while (has('+') || has('-')) {
      final op = take();
      final r = mul();

      v = op == '+' ? v + r : v - r;
    }

    return v;
  }

  bool primaryStart() {
    if (p >= t.length) {
      return false;
    }

    final x = t[p];

    return x == '(' ||
        x == 'pi' ||
        x == 'e' ||
        x == 'Ans' ||
        x == 'sqrt' ||
        x == 'sin' ||
        x == 'cos' ||
        x == 'tan' ||
        x == 'asin' ||
        x == 'acos' ||
        x == 'atan' ||
        x == 'log' ||
        x == 'ln' ||
        x == 'abs' ||
        RegExp(r'^\d').hasMatch(x);
  }

  double mul() {
    var v = power();

    while (true) {
      if (has('*') ||
          has('/') ||
          has('mod') ||
          has('P') ||
          has('C')) {
        final op = take();
        final r = power();

        if (op == '*') {
          v *= r;
        } else if (op == '/') {
          if (r == 0) {
            throw const FormatException();
          }

          v /= r;
        } else if (op == 'mod') {
          v %= r;
        } else if (op == 'P') {
          v = permutation(v, r);
        } else {
          v = combination(v, r);
        }
      } else if (primaryStart()) {
        v *= power();
      } else {
        break;
      }
    }

    return v;
  }

  double power() {
    var v = unary();

    if (has('^')) {
      take();
      v = math.pow(v, power()).toDouble();
    }

    return v;
  }

  double unary() {
    if (has('+')) {
      take();
      return unary();
    }

    if (has('-')) {
      take();
      return -unary();
    }

    var v = primary();

    while (has('%')) {
      take();
      v /= 100;
    }

    while (has('!')) {
      take();
      v = factorial(v);
    }

    return v;
  }

  double primary() {
    final x = take();

    if (x == '(') {
      final v = addSub();

      if (!has(')')) {
        throw const FormatException();
      }

      take();
      return v;
    }

    if (x == 'pi') {
      return math.pi;
    }

    if (x == 'e') {
      return math.e;
    }

    if (x == 'Ans') {
      return ans;
    }

    if (RegExp(r'^\d').hasMatch(x)) {
      return double.parse(x);
    }

    const funcs = {
      'sqrt',
      'sin',
      'cos',
      'tan',
      'asin',
      'acos',
      'atan',
      'log',
      'ln',
      'abs',
    };

    if (funcs.contains(x)) {
      final arg = has('(') ? functionArg() : unary();

      switch (x) {
        case 'sqrt':
          return math.sqrt(arg);

        case 'sin':
          return math.sin(toRad(arg));

        case 'cos':
          return math.cos(toRad(arg));

        case 'tan':
          return math.tan(toRad(arg));

        case 'asin':
          return fromRad(math.asin(arg));

        case 'acos':
          return fromRad(math.acos(arg));

        case 'atan':
          return fromRad(math.atan(arg));

        case 'log':
          return math.log(arg) / math.ln10;

        case 'ln':
          return math.log(arg);

        case 'abs':
          return arg.abs();
      }
    }

    throw const FormatException();
  }

  double functionArg() {
    take();

    final v = addSub();

    if (!has(')')) {
      throw const FormatException();
    }

    take();

    return v;
  }

  double toRad(double v) {
    return degrees ? v * math.pi / 180 : v;
  }

  double fromRad(double v) {
    return degrees ? v * 180 / math.pi : v;
  }
}

double factorial(double x) {
  final n = x.round();

  if (n < 0 ||
      (x - n).abs() > 1e-9 ||
      n > 170) {
    throw const FormatException();
  }

  var r = 1.0;

  for (int i = 2; i <= n; i++) {
    r *= i;
  }

  return r;
}

double permutation(double a, double b) {
  final n = a.round();
  final r = b.round();

  if (n < 0 || r < 0 || r > n) {
    throw const FormatException();
  }

  var v = 1.0;

  for (int i = 0; i < r; i++) {
    v *= n - i;
  }

  return v;
}

double combination(double a, double b) {
  final n = a.round();
  final r0 = b.round();

  if (n < 0 || r0 < 0 || r0 > n) {
    throw const FormatException();
  }

  final r = math.min(r0, n - r0);

  var v = 1.0;

  for (int i = 1; i <= r; i++) {
    v = v * (n - r + i) / i;
  }

  return v;
}