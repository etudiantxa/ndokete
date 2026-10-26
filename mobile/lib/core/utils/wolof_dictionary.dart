class WolofDictionary {
  static const Map<String, String> frToWolof = {
    'Bienvenue': 'Dalal ak jamm',
    'Commandes': 'Komand yi',
    'Clients': 'Kiliyan yi',
    'Mesures': 'Natt yi',
    'Trésorerie': 'Koom-koom',
    'Payer': 'Fay',
    'Catalogue': 'Bitik',
    'Urgent': 'Gaaw',
    'Ajouter': 'Yokkal',
    'Acompte': 'Denc',
    'Mon Profil': 'Sama Profil',
  };

  static String translate(String text) {
    return frToWolof[text] ?? text;
  }
}
