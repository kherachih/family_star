import '../../models/task.dart';
import '../../models/reward.dart';
import '../../models/sanction.dart';

class TutorialSelections {
  final Set<String> selectedTaskIds;
  final Set<String> selectedRewardIds;
  final Set<String> selectedSanctionIds;
  final List<Task> tasks;
  final List<Reward> rewards;
  final List<Sanction> sanctions;

  TutorialSelections({
    this.selectedTaskIds = const {},
    this.selectedRewardIds = const {},
    this.selectedSanctionIds = const {},
    this.tasks = const [],
    this.rewards = const [],
    this.sanctions = const [],
  });

  TutorialSelections copyWith({
    Set<String>? selectedTaskIds,
    Set<String>? selectedRewardIds,
    Set<String>? selectedSanctionIds,
    List<Task>? tasks,
    List<Reward>? rewards,
    List<Sanction>? sanctions,
  }) {
    return TutorialSelections(
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      selectedRewardIds: selectedRewardIds ?? this.selectedRewardIds,
      selectedSanctionIds: selectedSanctionIds ?? this.selectedSanctionIds,
      tasks: tasks ?? this.tasks,
      rewards: rewards ?? this.rewards,
      sanctions: sanctions ?? this.sanctions,
    );
  }

  bool get hasSelectedTasks => selectedTaskIds.isNotEmpty;
  bool get hasSelectedRewards => selectedRewardIds.isNotEmpty;
  bool get hasSelectedSanctions => selectedSanctionIds.isNotEmpty;
  bool get hasAnySelections => hasSelectedTasks || hasSelectedRewards || hasSelectedSanctions;
}