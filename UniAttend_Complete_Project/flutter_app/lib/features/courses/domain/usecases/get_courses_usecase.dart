// domain/usecases/get_courses_usecase.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/models.dart';
import '../repositories/course_repository.dart';

class GetCoursesUseCase {
  final CourseRepository _repo;
  GetCoursesUseCase(this._repo);
  Future<List<CourseModel>> call(String userId) =>
      _repo.getCoursesForStudent(userId);
}

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class CourseEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCourses extends CourseEvent {
  final String userId;
  LoadCourses(this.userId);
  @override
  List<Object?> get props => [userId];
}

class OpenSession extends CourseEvent {
  final String courseId;
  final ClassType classType;
  final double lat;
  final double lng;
  OpenSession(
      {required this.courseId,
      required this.classType,
      required this.lat,
      required this.lng});
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class CourseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CoursesLoaded extends CourseState {
  final List<CourseModel> courses;
  final List<AttendanceSession> activeSessions;
  CoursesLoaded({required this.courses, required this.activeSessions});
  @override
  List<Object?> get props => [courses, activeSessions];
}

class CourseError extends CourseState {
  final String message;
  CourseError(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetCoursesUseCase getCoursesUseCase;
  final CourseRepository courseRepository;

  CourseBloc({required this.getCoursesUseCase, required this.courseRepository})
      : super(CourseInitial()) {
    on<LoadCourses>(_onLoadCourses);
  }

  Future<void> _onLoadCourses(
      LoadCourses event, Emitter<CourseState> emit) async {
    emit(CourseLoading());
    try {
      final courses = await getCoursesUseCase(event.userId);
      final activeSessions = <AttendanceSession>[];
      for (final course in courses) {
        final active = await courseRepository.getActiveSession(course.id);
        if (active != null) {
          activeSessions.add(active);
        }
      }
      emit(CoursesLoaded(courses: courses, activeSessions: activeSessions));
    } catch (e) {
      emit(CourseError(e.toString()));
    }
  }
}
