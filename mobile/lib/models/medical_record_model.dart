class PrescriptionModel {
  final int id;
  final String medicament;
  final String? dosage;
  final String? posologie;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool isActive;
  final DateTime createdAt;

  const PrescriptionModel({
    required this.id,
    required this.medicament,
    this.dosage,
    this.posologie,
    this.dateDebut,
    this.dateFin,
    required this.isActive,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> j) => PrescriptionModel(
        id:         j['id'] as int,
        medicament: j['medicament'] as String,
        dosage:     j['dosage'] as String?,
        posologie:  j['posologie'] as String?,
        dateDebut:  j['date_debut'] != null ? DateTime.parse(j['date_debut']) : null,
        dateFin:    j['date_fin']   != null ? DateTime.parse(j['date_fin'])   : null,
        isActive:   j['is_active'] as bool,
        createdAt:  DateTime.parse(j['created_at'] as String),
      );
}

class ConsultationModel {
  final int id;
  final DateTime dateConsult;
  final String? diagnostic;
  final String? observations;
  final DateTime createdAt;

  const ConsultationModel({
    required this.id,
    required this.dateConsult,
    this.diagnostic,
    this.observations,
    required this.createdAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> j) => ConsultationModel(
        id:           j['id'] as int,
        dateConsult:  DateTime.parse(j['date_consult'] as String),
        diagnostic:   j['diagnostic'] as String?,
        observations: j['observations'] as String?,
        createdAt:    DateTime.parse(j['created_at'] as String),
      );
}

class LabResultModel {
  final int id;
  final String examen;
  final String? valeur;
  final String? unite;
  final String? norme;
  final String? statut;
  final DateTime? dateExamen;

  const LabResultModel({
    required this.id,
    required this.examen,
    this.valeur,
    this.unite,
    this.norme,
    this.statut,
    this.dateExamen,
  });

  factory LabResultModel.fromJson(Map<String, dynamic> j) => LabResultModel(
        id:         j['id'] as int,
        examen:     j['examen'] as String,
        valeur:     j['valeur'] as String?,
        unite:      j['unite'] as String?,
        norme:      j['norme'] as String?,
        statut:     j['statut'] as String?,
        dateExamen: j['date_examen'] != null ? DateTime.parse(j['date_examen']) : null,
      );
}

class MedicalRecordModel {
  final int id;
  final int patientId;
  final String? antecedents;
  final String? allergies;
  final String? traitements;
  final String? notesMedecin;
  final DateTime dateCreation;
  final List<PrescriptionModel> prescriptions;
  final List<ConsultationModel> consultations;
  final List<LabResultModel>    labResults;

  const MedicalRecordModel({
    required this.id,
    required this.patientId,
    this.antecedents,
    this.allergies,
    this.traitements,
    this.notesMedecin,
    required this.dateCreation,
    required this.prescriptions,
    required this.consultations,
    required this.labResults,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> j) => MedicalRecordModel(
        id:            j['id'] as int,
        patientId:     j['patient_id'] as int,
        antecedents:   j['antecedents'] as String?,
        allergies:     j['allergies'] as String?,
        traitements:   j['traitements'] as String?,
        notesMedecin:  j['notes_medecin'] as String?,
        dateCreation:  DateTime.parse(j['date_creation'] as String),
        prescriptions: (j['prescriptions'] as List? ?? [])
            .map((e) => PrescriptionModel.fromJson(e)).toList(),
        consultations: (j['consultations'] as List? ?? [])
            .map((e) => ConsultationModel.fromJson(e)).toList(),
        labResults:    (j['lab_results'] as List? ?? [])
            .map((e) => LabResultModel.fromJson(e)).toList(),
      );
}
