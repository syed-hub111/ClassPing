import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/expected_opportunity.dart';
import 'api_provider.dart';

final tutorAuthorizedClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.tutorGetAuthorizedClasses();
});

final tutorClassStudentsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, classId) async {
  final api = ref.watch(apiServiceProvider);
  return api.tutorGetClassStudents(classId);
});

final tutorPendingOpportunitiesProvider =
    FutureProvider.autoDispose.family<List<ExpectedOpportunity>, String>((ref, classId) async {
  final api = ref.watch(apiServiceProvider);
  return api.tutorGetPendingOpportunities(classId);
});

class RollCallState {
  final ClassModel? selectedClass;
  final ExpectedOpportunity? selectedOpportunity;
  final String subject;
  final Map<String, String> studentStatuses; // studentId -> PRESENT | LATE | ABSENT
  final List<Map<String, dynamic>> students;
  final String step; // MARK | REVIEW | LOCKED
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, dynamic>? confirmationResult;

  const RollCallState({
    this.selectedClass,
    this.selectedOpportunity,
    this.subject = '',
    this.studentStatuses = const {},
    this.students = const [],
    this.step = 'MARK',
    this.isSubmitting = false,
    this.errorMessage,
    this.confirmationResult,
  });

  RollCallState copyWith({
    ClassModel? selectedClass,
    ExpectedOpportunity? selectedOpportunity,
    String? subject,
    Map<String, String>? studentStatuses,
    List<Map<String, dynamic>>? students,
    String? step,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Map<String, dynamic>? confirmationResult,
  }) {
    return RollCallState(
      selectedClass: selectedClass ?? this.selectedClass,
      selectedOpportunity: selectedOpportunity ?? this.selectedOpportunity,
      subject: subject ?? this.subject,
      studentStatuses: studentStatuses ?? this.studentStatuses,
      students: students ?? this.students,
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmationResult: confirmationResult ?? this.confirmationResult,
    );
  }
}

class RollCallNotifier extends Notifier<RollCallState> {
  @override
  RollCallState build() => const RollCallState();

  void initForSession({
    required ClassModel classModel,
    required ExpectedOpportunity opportunity,
    required List<Map<String, dynamic>> students,
  }) {
    final initialMap = <String, String>{};
    for (final s in students) {
      final sId = s['studentId'] as String;
      initialMap[sId] = 'PRESENT';
    }

    state = RollCallState(
      selectedClass: classModel,
      selectedOpportunity: opportunity,
      subject: opportunity.actualSubject ?? '',
      students: students,
      studentStatuses: initialMap,
      step: 'MARK',
    );
  }

  void setSubject(String subject) {
    state = state.copyWith(subject: subject, clearError: true);
  }

  void setStudentStatus(String studentId, String status) {
    final updated = Map<String, String>.from(state.studentStatuses);
    updated[studentId] = status;
    state = state.copyWith(studentStatuses: updated, clearError: true);
  }

  void markAll(String status) {
    final updated = <String, String>{};
    for (final s in state.students) {
      final sId = s['studentId'] as String;
      updated[sId] = status;
    }
    state = state.copyWith(studentStatuses: updated, clearError: true);
  }

  bool validateAndProceedToReview() {
    if (state.subject.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter or select a subject.');
      return false;
    }
    if (state.students.isEmpty) {
      state = state.copyWith(errorMessage: 'No students enrolled in this class to mark.');
      return false;
    }
    state = state.copyWith(step: 'REVIEW', clearError: true);
    return true;
  }

  void backToMark() {
    state = state.copyWith(step: 'MARK', clearError: true);
  }

  Future<bool> confirmAndLock() async {
    if (state.selectedOpportunity == null || state.selectedClass == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final api = ref.read(apiServiceProvider);

      final records = state.students.map((s) {
        final sId = s['studentId'] as String;
        final sName = s['name'] as String;
        final status = state.studentStatuses[sId] ?? 'PRESENT';
        return {
          'studentId': sId,
          'studentName': sName,
          'status': status,
        };
      }).toList();

      final result = await api.tutorConfirmAttendance(
        opportunityId: state.selectedOpportunity!.opportunityId,
        classId: state.selectedClass!.classId,
        subject: state.subject.trim(),
        records: records,
      );

      state = state.copyWith(
        isSubmitting: false,
        step: 'LOCKED',
        confirmationResult: result,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final rollCallProvider = NotifierProvider.autoDispose<RollCallNotifier, RollCallState>(RollCallNotifier.new);
