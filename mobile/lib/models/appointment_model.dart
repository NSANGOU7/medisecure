class AppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final DateTime dateRdv;
  final int duration;
  final String statut;
  final String? motif;
  final String? notes;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateRdv,
    required this.duration,
    required this.statut,
    this.motif,
    this.notes,
    required this.createdAt,
  });

  bool get isConfirmed  => statut == 'confirmed';
  bool get isPending    => statut == 'pending';
  bool get isCancelled  => statut == 'cancelled';
  bool get isCompleted  => statut == 'completed';

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        id:        j['id'] as int,
        patientId: j['patient_id'] as int,
        doctorId:  j['doctor_id'] as int,
        dateRdv:   DateTime.parse(j['date_rdv'] as String),
        duration:  j['duration'] as int,
        statut:    j['statut'] as String,
        motif:     j['motif'] as String?,
        notes:     j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
