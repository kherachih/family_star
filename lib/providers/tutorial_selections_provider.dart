import 'package:flutter/foundation.dart';
import '../models/tutorial_selections.dart';
import '../models/task.dart';
import '../models/reward.dart';
import '../models/sanction.dart';

class TutorialSelectionsProvider with ChangeNotifier {
  TutorialSelections _selections = TutorialSelections();
  
  TutorialSelections get selections => _selections;
  
  // Gestion des tâches
  void toggleTaskSelection(String taskId) {
    Set<String> newSelectedTaskIds = Set<String>.from(_selections.selectedTaskIds);
    if (newSelectedTaskIds.contains(taskId)) {
      newSelectedTaskIds.remove(taskId);
    } else {
      newSelectedTaskIds.add(taskId);
    }
    
    _selections = _selections.copyWith(selectedTaskIds: newSelectedTaskIds);
    notifyListeners();
  }
  
  void setTasks(List<Task> tasks) {
    _selections = _selections.copyWith(tasks: tasks);
    notifyListeners();
  }
  
  List<Task> getSelectedTasks() {
    return _selections.tasks.where((task) => _selections.selectedTaskIds.contains(task.id!)).toList();
  }
  
  // Gestion des récompenses
  void toggleRewardSelection(String rewardId) {
    Set<String> newSelectedRewardIds = Set<String>.from(_selections.selectedRewardIds);
    if (newSelectedRewardIds.contains(rewardId)) {
      newSelectedRewardIds.remove(rewardId);
    } else {
      newSelectedRewardIds.add(rewardId);
    }
    
    _selections = _selections.copyWith(selectedRewardIds: newSelectedRewardIds);
    notifyListeners();
  }
  
  void setRewards(List<Reward> rewards) {
    _selections = _selections.copyWith(rewards: rewards);
    notifyListeners();
  }
  
  List<Reward> getSelectedRewards() {
    return _selections.rewards.where((reward) => _selections.selectedRewardIds.contains(reward.id!)).toList();
  }
  
  // Gestion des sanctions
  void toggleSanctionSelection(String sanctionId) {
    Set<String> newSelectedSanctionIds = Set<String>.from(_selections.selectedSanctionIds);
    if (newSelectedSanctionIds.contains(sanctionId)) {
      newSelectedSanctionIds.remove(sanctionId);
    } else {
      newSelectedSanctionIds.add(sanctionId);
    }
    
    _selections = _selections.copyWith(selectedSanctionIds: newSelectedSanctionIds);
    notifyListeners();
  }
  
  void setSanctions(List<Sanction> sanctions) {
    _selections = _selections.copyWith(sanctions: sanctions);
    notifyListeners();
  }
  
  List<Sanction> getSelectedSanctions() {
    return _selections.sanctions.where((sanction) => _selections.selectedSanctionIds.contains(sanction.id!)).toList();
  }
  
  // Réinitialiser toutes les sélections
  void resetSelections() {
    _selections = TutorialSelections();
    notifyListeners();
  }
}