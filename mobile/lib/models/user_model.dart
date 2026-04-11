class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String? telephone;
  final String statut;
  final DateTime dateCreation;

  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    required this.statut,
    required this.dateCreation,
  });

  String get fullName => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id:           j['id'] as int,
        nom:          j['nom'] as String,
        prenom:       j['prenom'] as String,
        email:        j['email'] as String,
        role:         j['role'] as String,
        telephone:    j['telephone'] as String?,
        statut:       j['statut'] as String,
        dateCreation: DateTime.parse(j['date_creation'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':           id,
        'nom':          nom,
        'prenom':       prenom,
        'email':        email,
        'role':         role,
        'telephone':    telephone,
        'statut':       statut,
        'date_creation': dateCreation.toIso8601String(),
      };
}
