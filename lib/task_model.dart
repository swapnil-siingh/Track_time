

class Task {
  String name;
  Duration elapsedTime;
  bool isRunning;
  bool isCompleted;

  Task({
    required this.name,
    this.elapsedTime = Duration.zero,
    this.isRunning = false,
    this.isCompleted = false,
    
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'elapsedTime': elapsedTime.inSeconds,
      'isRunning': isRunning,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'],
      elapsedTime: Duration(seconds: json['elapsedTime']),
      isRunning: json['isRunning'],
      isCompleted: json['isCompleted'],
    );
  }
}

class Profile {
  String name;
  List<Task> tasks;

  Profile({
    required this.name,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    List<Task> tasks =
        (json['tasks'] as List).map((e) => Task.fromJson(e)).toList();
    return Profile(
      name: json['name'],
      tasks: tasks,
    );
  }
}
