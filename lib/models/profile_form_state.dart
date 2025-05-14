import 'package:flutter/material.dart';

class ProfileFormState {
  final TextEditingController nameController;
  final DateTime? selectedDate;
  final String? selectedMood;
  final Set<String> selectedInterests;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSubmissionTime;
  final int retryCount;

  ProfileFormState({
    required this.nameController,
    this.selectedDate,
    this.selectedMood,
    Set<String>? selectedInterests,
    this.isLoading = false,
    this.errorMessage,
    this.lastSubmissionTime,
    this.retryCount = 0,
  }) : selectedInterests = selectedInterests ?? {};

  ProfileFormState copyWith({
    TextEditingController? nameController,
    DateTime? selectedDate,
    String? selectedMood,
    Set<String>? selectedInterests,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSubmissionTime,
    int? retryCount,
  }) {
    return ProfileFormState(
      nameController: nameController ?? this.nameController,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedMood: selectedMood ?? this.selectedMood,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSubmissionTime: lastSubmissionTime ?? this.lastSubmissionTime,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  double get formProgress {
    int completedFields = 0;
    if (nameController.text.isNotEmpty) completedFields++;
    if (selectedDate != null) completedFields++;
    if (selectedMood != null) completedFields++;
    if (selectedInterests.isNotEmpty) completedFields++;
    return completedFields / 4;
  }

  bool get canSubmit {
    return nameController.text.isNotEmpty &&
        selectedDate != null &&
        selectedMood != null &&
        selectedInterests.isNotEmpty &&
        !isLoading &&
        (lastSubmissionTime == null ||
            DateTime.now().difference(lastSubmissionTime!) >
                const Duration(seconds: 2));
  }
} 