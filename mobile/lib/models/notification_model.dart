class NotificationModel {
  final int id;
  final String? titre;
  final String message;
  final String type;
  final String statut;
  final DateTime dateEnvoi;

  const NotificationModel({
    required this.id,
    this.titre,
    required this.message,
    required this.type,
    required this.statut,
    required this.dateEnvoi,
  });

  bool get isUnread => statut == 'sent';

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id:        j['id'] as int,
        titre:     j['titre'] as String?,
        message:   j['message'] as String,
        type:      j['type'] as String,
        statut:    j['statut'] as String,
        dateEnvoi: DateTime.parse(j['date_envoi'] as String),
      );
}
