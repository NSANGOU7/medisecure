import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medical_record_model.dart';
import 'api_client.dart';

class MedicalRecordService {
  final _dio = ApiClient().dio;

  Future<MedicalRecordModel> getMyRecord() async {
    final res = await _dio.get('/records/my');
    return MedicalRecordModel.fromJson(res.data);
  }

  Future<MedicalRecordModel> getPatientRecord(int patientId) async {
    final res = await _dio.get('/records/$patientId');
    return MedicalRecordModel.fromJson(res.data);
  }

  Future<MedicalRecordModel> updateRecord(int patientId, Map<String, dynamic> data) async {
    final res = await _dio.put('/records/$patientId', data: data);
    return MedicalRecordModel.fromJson(res.data);
  }

  Future<PrescriptionModel> addPrescription(int patientId, Map<String, dynamic> data) async {
    final res = await _dio.post('/records/$patientId/prescriptions', data: data);
    return PrescriptionModel.fromJson(res.data);
  }

  Future<void> deactivatePrescription(int patientId, int rxId) async {
    await _dio.delete('/records/$patientId/prescriptions/$rxId');
  }

  Future<ConsultationModel> addConsultation(int patientId, Map<String, dynamic> data) async {
    final res = await _dio.post('/records/$patientId/consultations', data: data);
    return ConsultationModel.fromJson(res.data);
  }

  Future<LabResultModel> addLabResult(int patientId, Map<String, dynamic> data) async {
    final res = await _dio.post('/records/$patientId/lab-results', data: data);
    return LabResultModel.fromJson(res.data);
  }
}

final recordServiceProvider = Provider((_) => MedicalRecordService());

final myRecordProvider = FutureProvider.autoDispose<MedicalRecordModel>((ref) async {
  return ref.watch(recordServiceProvider).getMyRecord();
});
