import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student.dart';
import '../models/tutor.dart';
import '../models/class_model.dart';
import '../models/academic_year.dart';
import '../models/expected_opportunity.dart';
import 'api_provider.dart';

final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetDashboardStats();
});

final adminStudentsProvider = FutureProvider.autoDispose<List<Student>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetStudents();
});

final adminTutorsProvider = FutureProvider.autoDispose<List<Tutor>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetTutors();
});

final adminClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetClasses();
});

final adminAcademicYearsProvider = FutureProvider.autoDispose<List<AcademicYear>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetAcademicYears();
});

final adminOpportunitiesProvider = FutureProvider.autoDispose<List<ExpectedOpportunity>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.adminGetPendingAndMissedOpportunities();
});
