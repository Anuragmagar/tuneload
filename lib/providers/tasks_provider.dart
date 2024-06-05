import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneload/models/tasks.dart';

class TasksNotifier extends Notifier<Set<Tasks>> {
  @override
  Set<Tasks> build() {
    return {
      Tasks(taskId: '1234', progress: 12, imageUrl: 'hello.com'),
    };
  }

  void addTasks(Tasks task) {
    if (!state.contains(task)) {
      state = {...state, task};
    }
  }
}

final tasksNotifierProvider = NotifierProvider<TasksNotifier, Set<Tasks>>(() {
  return TasksNotifier();
});
