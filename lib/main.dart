import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'student.dart';

// ---------- THEME COLORS ----------
const Color bg = Color(0xFF0E1124);
const Color cardColor = Color(0xFF181C36);
const Color borderColor = Color(0xFF2A2F55);
const Color muted = Color(0xFF9AA0C3);
const Color cyan = Color(0xFF22D3EE);
const Color green = Color(0xFF4ADE80);
const Color amber = Color(0xFFFBBF24);
const List<Color> brandGradient = [Color(0xFF6C63FF), Color(0xFF8E54E9)];

// Same colour with a different opacity (0.0 - 1.0)
Color alpha(Color c, double o) => c.withAlpha((o * 255).round());

const Map<String, Color> courseColors = {
  'CSE': Color(0xFF6C63FF),
  'ECE': Color(0xFF22D3EE),
  'EEE': Color(0xFFFBBF24),
  'MECH': Color(0xFFF97316),
  'IT': Color(0xFF4ADE80),
  'AI&DS': Color(0xFFEC4899),
};
final List<String> courseList = courseColors.keys.toList();

BoxDecoration panelDecoration() => BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    );

void main() => runApp(const StateApp());

class StateApp extends StatelessWidget {
  const StateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C63FF),
        scaffoldBackgroundColor: bg,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ---------- STATE ----------
  final List<Student> students = [];
  final TextEditingController searchCtrl = TextEditingController();
  int nextId = 1;
  String query = '';
  String roundTripStatus = 'Not run yet';

  // ---------- SERIALIZATION ----------
  // Object -> JSON
  String get prettyJson => const JsonEncoder.withIndent('  ')
      .convert(students.map((s) => s.toJson()).toList());

  // JSON -> Object (full round trip)
  void roundTrip() {
    final String raw = jsonEncode(students.map((s) => s.toJson()).toList());
    final List decoded = jsonDecode(raw);
    final rebuilt = decoded
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() {
      students
        ..clear()
        ..addAll(rebuilt);
      roundTripStatus =
          '✔ ${rebuilt.length} objects → ${raw.length} chars → ${rebuilt.length} objects';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Round trip OK: ${rebuilt.length} students')),
    );
  }

  // ---------- ACTIONS ----------
  void addStudent(String name, String course) {
    setState(() {
      students.add(Student(id: nextId++, name: name, course: course));
    });
  }

  void addSamples() {
    setState(() {
      students.addAll([
        Student(id: nextId++, name: 'Aarav', course: 'CSE'),
        Student(id: nextId++, name: 'Meera', course: 'ECE'),
        Student(id: nextId++, name: 'Rohan', course: 'AI&DS'),
        Student(id: nextId++, name: 'Sana', course: 'IT'),
        Student(id: nextId++, name: 'Dev', course: 'CSE'),
      ]);
    });
  }

  void removeStudent(Student s) {
    final index = students.indexOf(s);
    setState(() => students.remove(s));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${s.name} removed'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => setState(() {
            students.insert(index.clamp(0, students.length), s);
          }),
        ),
      ),
    );
  }

  List<Student> get filtered {
    final q = query.toLowerCase();
    return students
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.course.toLowerCase().contains(q))
        .toList();
  }

  String get topCourse {
    if (students.isEmpty) return '—';
    String best = courseList.first;
    int bestCount = 0;
    for (final c in courseList) {
      final n = students.where((s) => s.course == c).length;
      if (n > bestCount) {
        best = c;
        bestCount = n;
      }
    }
    return best;
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // ---------- ADD SHEET ----------
  void openAddSheet() {
    final nameCtrl = TextEditingController();
    String selected = courseList.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void submit() {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              addStudent(name, selected);
              Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New student',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Student name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Course', style: TextStyle(color: muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: courseList.map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected == c,
                        selectedColor: alpha(courseColors[c]!, 0.35),
                        onSelected: (_) => setSheet(() => selected = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Save student'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      header(),
                      const SizedBox(height: 20),
                      statsRow(),
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: studentPanel()),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  courseChart(),
                                  const SizedBox(height: 20),
                                  jsonPanel(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            studentPanel(),
                            const SizedBox(height: 20),
                            courseChart(),
                            const SizedBox(height: 20),
                            jsonPanel(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8E54E9), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Hub',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Live state management  ⇄  JSON serialization',
                  style: TextStyle(color: alpha(Colors.white, 0.85)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pill('setState()'),
                    pill('toJson()'),
                    pill('fromJson()'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: alpha(Colors.white, 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded,
                size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: alpha(Colors.black, 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: Colors.white)),
    );
  }

  Widget statsRow() {
    final distinct = students.map((s) => s.course).toSet().length;
    return Row(
      children: [
        Expanded(
            child: statCard(
                Icons.groups_rounded, '${students.length}', 'Students', cyan)),
        const SizedBox(width: 12),
        Expanded(
            child: statCard(
                Icons.menu_book_rounded, '$distinct', 'Courses', amber)),
        const SizedBox(width: 12),
        Expanded(
            child: statCard(
                Icons.emoji_events_rounded, topCourse, 'Top course', green)),
      ],
    );
  }

  Widget statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alpha(color, 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800)),
          ),
          Text(label, style: const TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget studentPanel() {
    final list = filtered;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Students',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: alpha(cyan, 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${students.length}',
                    style: const TextStyle(color: cyan)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchCtrl,
            onChanged: (v) => setState(() => query = v),
            decoration: InputDecoration(
              hintText: 'Search by name or course',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: alpha(Colors.white, 0.04),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (students.isEmpty)
            emptyState()
          else if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No matches', style: TextStyle(color: muted))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) => studentTile(list[index]),
            ),
        ],
      ),
    );
  }

  Widget emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: alpha(muted, 0.6)),
            const SizedBox(height: 10),
            const Text('No students yet', style: TextStyle(color: muted)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: addSamples,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Load sample students'),
            ),
          ],
        ),
      ),
    );
  }

  Widget studentTile(Student s) {
    final color = courseColors[s.course] ?? brandGradient.first;
    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => removeStudent(s),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alpha(color, 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alpha(color, 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color, alpha(color, 0.55)]),
              ),
              child: Text(
                s.name[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('ID #${s.id}',
                      style: const TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: alpha(color, 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.course,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: muted),
              onPressed: () => removeStudent(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget courseChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Students per course',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...courseList.map((c) {
            final count = students.where((s) => s.course == c).length;
            final fraction = students.isEmpty ? 0.0 : count / students.length;
            final color = courseColors[c]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(c, style: const TextStyle(color: muted)),
                  ),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: alpha(Colors.white, 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: fraction),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [alpha(color, 0.6), color]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text('$count',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Colours the JSON text: keys cyan, strings green, numbers amber
  List<TextSpan> highlight(String src) {
    final spans = <TextSpan>[];
    final re = RegExp(r'("[^"]*")(\s*:)?|(-?\d+)');
    int last = 0;
    for (final m in re.allMatches(src)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: src.substring(last, m.start),
            style: const TextStyle(color: muted)));
      }
      if (m.group(1) != null) {
        final isKey = m.group(2) != null;
        spans.add(TextSpan(
            text: m.group(1),
            style: TextStyle(color: isKey ? cyan : green)));
        if (isKey) {
          spans.add(TextSpan(
              text: m.group(2), style: const TextStyle(color: muted)));
        }
      } else {
        spans.add(TextSpan(
            text: m.group(3), style: const TextStyle(color: amber)));
      }
      last = m.end;
    }
    if (last < src.length) {
      spans.add(TextSpan(
          text: src.substring(last), style: const TextStyle(color: muted)));
    }
    return spans;
  }

  Widget jsonPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                dot(const Color(0xFFFF5F57)),
                dot(const Color(0xFFFEBC2E)),
                dot(const Color(0xFF28C840)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('students.json',
                      style: TextStyle(color: muted, fontSize: 13)),
                ),
                IconButton(
                  tooltip: 'Copy JSON',
                  icon: const Icon(Icons.copy_rounded, size: 18, color: muted),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prettyJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON copied')),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              child: SelectableText.rich(
                TextSpan(
                  children: highlight(prettyJson),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: students.isEmpty ? null : roundTrip,
                    icon: const Icon(Icons.sync),
                    label: const Text('Encode → Decode (fromJson)'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(roundTripStatus,
                    style: const TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dot(Color c) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}