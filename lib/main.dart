import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';
import 'task_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: MaterialApp(
        theme: ThemeData.dark(), // Set dark theme here
        home: const ProfileScreen(),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return ListView.builder(
            itemCount: taskProvider.profiles.length,
            itemBuilder: (context, index) {
              Profile profile = taskProvider.profiles[index];
              return ListTile(
                title: Text(profile.name),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TaskListScreen(profileIndex: index),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createNewProfile(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController profileNameController =
            TextEditingController();
        final TextEditingController taskCountController =
            TextEditingController();
        int taskCount = 0;
        List<TextEditingController> taskNameControllers = [];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Profile'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: profileNameController,
                      decoration:
                          const InputDecoration(labelText: 'Profile Name'),
                    ),
                    TextField(
                      controller: taskCountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Enter total tasks'),
                      onChanged: (value) {
                        setState(() {
                          taskCount = int.tryParse(value) ?? 0;
                          taskNameControllers = List.generate(
                            taskCount,
                            (index) => TextEditingController(),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(
                      taskCount,
                      (index) => TextField(
                        controller: taskNameControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Task ${index + 1} Name',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    List<String> taskNames = taskNameControllers
                        .map((controller) => controller.text)
                        .toList();
                    Provider.of<TaskProvider>(context, listen: false)
                        .createProfile(profileNameController.text, taskNames);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TaskListScreen extends StatelessWidget {
  final int profileIndex;

  const TaskListScreen({super.key, required this.profileIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          Profile profile = taskProvider.profiles[profileIndex];
          List<Task> tasks = profile.tasks;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              Task task = tasks[index];
              return TaskTile(
                  task: task, profileIndex: profileIndex, taskIndex: index);
            },
          );
        },
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final int profileIndex;
  final int taskIndex;

  const TaskTile({
    super.key,
    required this.task,
    required this.profileIndex,
    required this.taskIndex,
  });

  get dialogTimer => null;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: task.isCompleted ? Colors.blue[500] : null,
      title: Text(task.name),
      subtitle: Text(_formatDuration(task.elapsedTime)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(task.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleTimer(profileIndex, taskIndex);
              _showTaskPrompt(context, task);
            },
          ),
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleCompletion(profileIndex, taskIndex);
            },
          ),
        ],
      ),
    );
  }

  void _showTaskPrompt(BuildContext context, Task task) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Timer? dialogTimer;
            void startTimer() {
              dialogTimer =
                  Timer.periodic(const Duration(seconds: 1), (Timer timer) {
                if (context.mounted) {
                  setState(() {});
                }
              });
            }

            if (task.isRunning) {
              startTimer();
            }

            return AlertDialog(
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(task.elapsedTime),
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon:
                          Icon(task.isRunning ? Icons.pause : Icons.play_arrow),
                      iconSize: 50,
                      onPressed: () {
                        Provider.of<TaskProvider>(context, listen: false)
                            .toggleTimer(profileIndex, taskIndex);
                        if (dialogTimer != null) {
                          dialogTimer!.cancel();
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (dialogTimer != null) {
        dialogTimer!.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
