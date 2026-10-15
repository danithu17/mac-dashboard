class Habit {
  final String id;
  final String name;
  final String category;
  final int target;
  final String icon;
  final String color;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.target,
    required this.icon,
    required this.color,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Coding',
      target: json['target'] ?? 7,
      icon: json['icon'] ?? '⚡',
      color: json['color'] ?? '#3b82f6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'target': target,
      'icon': icon,
      'color': color,
    };
  }
}
