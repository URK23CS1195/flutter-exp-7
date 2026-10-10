class Student {
  final int id;
  final String name;
  final String course;

  Student({
    required this.id,
    required this.name,
    required this.course,
  });

  // Dart object -> Map (ready for jsonEncode)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course': course,
    };
  }

  // Map (from jsonDecode) -> Dart object
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      course: json['course'],
    );
  }

  @override
  String toString() => 'Student(id: $id, name: $name, course: $course)';
}