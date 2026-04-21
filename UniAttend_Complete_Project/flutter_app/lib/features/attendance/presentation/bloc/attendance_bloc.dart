import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/device_service.dart';
import '../../../../shared/services/qr_service.dart';
import '../../domain/repositories/attendance_repository.dart';

// ─── Use Cases ────────────────────────────────────────────────────────────────
class CheckInUseCase {
  final AttendanceRepository _repo;
  CheckInUseCase(this._repo);
  Future<AttendanceRecord> call({
    required String sessionId,
    required UserModel user,
    required String deviceId,
    required String qrPayload,
    required double lat,
    required double lng,
  }) =>
      _repo.checkIn(
        sessionId: sessionId,
        studentId: user.id,
        studentName: user.fullName,
        matricNumber: user.matricNumber,
        department: user.department,
        deviceId: deviceId,
        qrPayload: qrPayload,
        latitude: lat,
        longitude: lng,
      );
}

class CheckOutUseCase {
  final AttendanceRepository _repo;
  CheckOutUseCase(this._repo);
  Future<AttendanceRecord> call({
    required String sessionId,
    required String studentId,
    required String deviceId,
    required String qrPayload,
    required double lat,
    required double lng,
  }) =>
      _repo.checkOut(
          sessionId: sessionId,
          studentId: studentId,
          deviceId: deviceId,
          qrPayload: qrPayload,
          latitude: lat,
          longitude: lng);
}

class GetSessionAttendanceUseCase {
  final AttendanceRepository _repo;
  GetSessionAttendanceUseCase(this._repo);
  Future<List<AttendanceRecord>> call(String sessionId) =>
      _repo.getSessionAttendance(sessionId);
}

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class AttendanceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScanAndCheckIn extends AttendanceEvent {
  final String qrPayload;
  final String expectedSessionId;
  final UserModel user;
  ScanAndCheckIn({
    required this.qrPayload,
    required this.expectedSessionId,
    required this.user,
  });
  @override
  List<Object?> get props => [qrPayload, expectedSessionId, user];
}

class ScanAndCheckOut extends AttendanceEvent {
  final String qrPayload;
  final String expectedSessionId;
  final UserModel user;
  ScanAndCheckOut({
    required this.qrPayload,
    required this.expectedSessionId,
    required this.user,
  });

  @override
  List<Object?> get props => [qrPayload, expectedSessionId, user];
}

class LoadSessionAttendance extends AttendanceEvent {
  final String sessionId;
  LoadSessionAttendance(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

// ─── States ───────────────────────────────────────────────────────────────────
abstract class AttendanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceCheckInSuccess extends AttendanceState {
  final AttendanceRecord record;
  AttendanceCheckInSuccess(this.record);
  @override
  List<Object?> get props => [record];
}

class AttendanceCheckOutSuccess extends AttendanceState {
  final AttendanceRecord record;
  AttendanceCheckOutSuccess(this.record);
  @override
  List<Object?> get props => [record];
}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  AttendanceLoaded(this.records);
  @override
  List<Object?> get props => [records];
}

class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetSessionAttendanceUseCase getSessionAttendanceUseCase;
  final LocationService locationService;
  final DeviceService deviceService;
  final QrService qrService;

  AttendanceBloc({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getSessionAttendanceUseCase,
    required this.locationService,
    required this.deviceService,
    required this.qrService,
  }) : super(AttendanceInitial()) {
    on<ScanAndCheckIn>(_onCheckIn);
    on<ScanAndCheckOut>(_onCheckOut);
    on<LoadSessionAttendance>(_onLoadAttendance);
  }

  Future<void> _onCheckIn(
      ScanAndCheckIn event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        emit(AttendanceError(
            'Could not get your GPS location. Please enable location services.'));
        return;
      }

      final deviceId = await deviceService.getDeviceId();
      final sessionId = qrService.validateQrPayload(event.qrPayload);
      if (sessionId == null) {
        emit(AttendanceError('Invalid or expired QR code. Please scan again.'));
        return;
      }
      if (sessionId != event.expectedSessionId) {
        emit(AttendanceError(
            'This QR code is for another session. Please scan the current class QR.'));
        return;
      }
      final record = await checkInUseCase(
        sessionId: sessionId,
        user: event.user,
        deviceId: deviceId,
        qrPayload: event.qrPayload,
        lat: position.latitude,
        lng: position.longitude,
      );
      emit(AttendanceCheckInSuccess(record));
    } catch (e) {
      emit(AttendanceError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onCheckOut(
      ScanAndCheckOut event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        emit(AttendanceError('GPS location required for check-out.'));
        return;
      }
      final deviceId = await deviceService.getDeviceId();
      final sessionId = qrService.validateQrPayload(event.qrPayload);
      if (sessionId == null) {
        emit(AttendanceError('Invalid or expired QR code. Please scan again.'));
        return;
      }
      if (sessionId != event.expectedSessionId) {
        emit(AttendanceError(
            'This QR code is for another session. Please scan the current class QR.'));
        return;
      }
      final record = await checkOutUseCase(
        sessionId: sessionId,
        studentId: event.user.id,
        deviceId: deviceId,
        qrPayload: event.qrPayload,
        lat: position.latitude,
        lng: position.longitude,
      );
      emit(AttendanceCheckOutSuccess(record));
    } catch (e) {
      emit(AttendanceError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadAttendance(
      LoadSessionAttendance event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final records = await getSessionAttendanceUseCase(event.sessionId);
      emit(AttendanceLoaded(records));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }
}
