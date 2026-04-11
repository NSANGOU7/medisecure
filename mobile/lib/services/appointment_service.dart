import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import 'api_client.dart';

class AppointmentService {
  final _dio = ApiClient().dio;

  Future<List<AppointmentModel>> getMyAppointments() async {
    final res = await _dio.get('/appointments/');
    return (res.data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<AppointmentModel> getAppointment(int id) async {
    final res = await _dio.get('/appointments/$id');
    return AppointmentModel.fromJson(res.data);
  }

  Future<AppointmentModel> createAppointment({
    required int doctorId,
    required DateTime dateRdv,
    int duration = 30,
    String? motif,
  }) async {
    final res = await _dio.post('/appointments/', data: {
      'doctor_id': doctorId,
      'date_rdv':  dateRdv.toIso8601String(),
      'duration':  duration,
      'motif':     motif,
    });
    return AppointmentModel.fromJson(res.data);
  }

  Future<AppointmentModel> updateAppointment(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/appointments/$id', data: data);
    return AppointmentModel.fromJson(res.data);
  }

  Future<void> cancelAppointment(int id) async {
    await _dio.delete('/appointments/$id');
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots(int doctorId, String date) async {
    final res = await _dio.get('/appointments/slots/$doctorId', queryParameters: {'date': date});
    return List<Map<String, dynamic>>.from(res.data);
  }
}

final appointmentServiceProvider = Provider((_) => AppointmentService());

final appointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) async {
  return ref.watch(appointmentServiceProvider).getMyAppointments();
});
