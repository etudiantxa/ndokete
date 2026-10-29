import { Injectable } from '@nestjs/common';

@Injectable()
export class AiMeasurementsService {
  parseText(text: string) {
    const measurements: Record<string, number> = {};
    let cleanText = text.toLowerCase();

    // Dictionnaire des nombres et mots clés Wolof & Français
    const wolofNumbers: Record<string, string> = {
      'teemeer': '100', 'téeméer': '100', 'temeer': '100',
      'fanweer': '30', 'ñett-fukk': '30', 'nett-fukk': '30',
      'nar-fukk': '20', 'ñar-fukk': '20', 'nari-fukk': '20',
      'fukk': '10',
      'juroom-fukk': '50', 'juróom-fukk': '50', 'juroom': '5',
      'nient-fukk': '40', 'ñent-fukk': '40',
      'juróom-benn': '6', 'juróom-ñaar': '7', 'juróom-ñett': '8', 'juróom-ñent': '9',
    };

    for (const [wWord, digit] of Object.entries(wolofNumbers)) {
      cleanText = cleanText.replace(new RegExp(wWord, 'g'), digit);
    }

    const extract = (keywords: string[]) => {
      for (const kw of keywords) {
        const regex = new RegExp(`${kw}[^0-9]{0,15}(\\d+(?:[\\.,]\\d+)?)`, 'i');
        const match = cleanText.match(regex);
        if (match && match[1]) {
          return parseFloat(match[1].replace(',', '.'));
        }
      }
      return null;
    };

    const mapping = [
      { keys: ['cou', 'tour de cou', 'tuuru kow'], field: 'cou' },
      { keys: ['epaule', 'épaules', 'largeur epaule', 'baari'], field: 'epaule' },
      { keys: ['poitrine', 'tour de poitrine', 'buste', 'potrin', 'pótrin'], field: 'poitrine' },
      { keys: ['bras', 'longueur bras', 'manche', 'loxo'], field: 'longueurBras' },
      { keys: ['boubou', 'longueur boubou'], field: 'longueurBoubou' },
      { keys: ['taille', 'tour de taille', 'biir'], field: 'taille' },
      { keys: ['bassin', 'hanche', 'hanches', 'gon'], field: 'bassin' },
      { keys: ['pantalon', 'longueur pantalon', 'jupe', 'longueur jupe'], field: 'longPantalon' },
      { keys: ['entrejambe'], field: 'entrejambe' },
      { keys: ['pointure', 'pointure chaussures', 'pied'], field: 'pointure' },
    ];

    for (const item of mapping) {
      const val = extract(item.keys);
      if (val !== null) {
        measurements[item.field] = val;
      }
    }

    return {
      success: true,
      data: measurements,
      message: `${Object.keys(measurements).length} mesure(s) extraite(s) en Français/Wolof par l'IA`,
    };
  }
}
