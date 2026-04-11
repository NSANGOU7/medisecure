class Validators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Ce champ est obligatoire' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email obligatoire';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);
    return re.hasMatch(v.trim()) ? null : 'Email invalide';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe obligatoire';
    if (v.length < 8) return 'Min. 8 caractères';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final re = RegExp(r'^\+?[\d\s\-]{7,15}$');
    return re.hasMatch(v.trim()) ? null : 'Numéro invalide';
  }
}
