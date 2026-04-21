import 'package:get_it/get_it.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/domain/usecases/get_courses_usecase.dart';
import '../../features/courses/presentation/bloc/course_bloc.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/device_service.dart';
import '../../shared/services/qr_service.dart';
import '../../shared/services/export_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Services
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<DeviceService>(() => DeviceService());
  sl.registerLazySingleton<QrService>(() => QrService());
  sl.registerLazySingleton<ExportService>(() => ExportService());
  sl.registerLazySingleton<ApiService>(() => ApiService());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(sl()));
  sl.registerLazySingleton<CourseRepository>(() => CourseRepositoryImpl(sl()));

  // Auth Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // Attendance Use Cases
  sl.registerLazySingleton(() => CheckInUseCase(sl()));
  sl.registerLazySingleton(() => CheckOutUseCase(sl()));
  sl.registerLazySingleton(() => GetSessionAttendanceUseCase(sl()));

  // Course Use Cases
  sl.registerLazySingleton(() => GetCoursesUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(
      loginUseCase: sl(), registerUseCase: sl(), authRepository: sl()));
  sl.registerFactory(() => AttendanceBloc(
        checkInUseCase: sl(),
        checkOutUseCase: sl(),
        getSessionAttendanceUseCase: sl(),
        locationService: sl(),
        deviceService: sl(),
        qrService: sl(),
      ));
  sl.registerFactory(
      () => CourseBloc(getCoursesUseCase: sl(), courseRepository: sl()));
}
