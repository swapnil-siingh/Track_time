import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';
import 'dart:async';
import 'dart:convert';

class TaskProvider with ChangeNotifier {
  List<Profile> _profiles = [];
  List<List<Timer?>> _timers = [];
  String _lastSavedDate = "";

  List<Profile> get profiles => _profiles;

  TaskProvider() {
    _loadData();
    _checkDateAndResetIfNeeded();
  }

  void createProfile(String profileName, List<String> taskNames) {
    Profile profile = Profile(
      name: profileName,
      tasks: List.generate(
        taskNames.length,
        (index) => Task(name: taskNames[index]),
      ),
    );
    _profiles.add(profile);
    _timers.add(List.generate(
        taskNames.length, (_) => null)); // Initialize timers for new profile
    _saveData();
    notifyListeners();
  }

  void toggleTimer(int profileIndex, int taskIndex) {
    Profile profile = _profiles[profileIndex];
    Task task = profile.tasks[taskIndex];

    if (_timers[profileIndex][taskIndex] != null) {
      // Timer is running, stop it
      _timers[profileIndex][taskIndex]?.cancel();
      _timers[profileIndex][taskIndex] = null;
    } else {
      // Timer is not running, start it
      _timers[profileIndex][taskIndex] =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        task.elapsedTime += const Duration(seconds: 1);
        notifyListeners();
        _saveData();
      });
    }

    task.isRunning = !task.isRunning;
    notifyListeners();
    _saveData();
  }

  void toggleCompletion(int profileIndex, int taskIndex) {
    _profiles[profileIndex].tasks[taskIndex].isCompleted =
        !_profiles[profileIndex].tasks[taskIndex].isCompleted;
    notifyListeners();
    _saveData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('profiles');
    if (data != null) {
      final List<dynamic> json = jsonDecode(data);
      _profiles = json.map((e) => Profile.fromJson(e)).toList();
      _timers = List.generate(_profiles.length, (_) => []);
      _lastSavedDate = prefs.getString('lastSavedDate') ?? "";
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_profiles.map((e) => e.toJson()).toList());
    prefs.setString('profiles', data);
    prefs.setString('lastSavedDate', _currentDate());
  }

  void _checkDateAndResetIfNeeded() {
    if (_lastSavedDate != _currentDate()) {
      for (var profile in _profiles) {
        for (var task in profile.tasks) {
          task.elapsedTime = Duration.zero;
        }
      }
      _lastSavedDate = _currentDate();
      _saveData();
    }
  }

  String _currentDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
}
