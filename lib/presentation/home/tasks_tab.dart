import 'package:flutter/material.dart';

/// Placeholder — inbox/tasks (E7) ainda não existe no backend.
class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        key: Key('tasks_placeholder'),
        'Em breve',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
