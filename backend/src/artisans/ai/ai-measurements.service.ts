import { Injectable } from '@nestjs/common';

@Injectable()
export class AiMeasurementsService {
  parseText(text: string) {
    const measurements: Record<string, number> = {};
    const lower = text.toLowerCase();

    const extract = (keywords: string[]) => {
      for (const kw of keywords) {
        const regex = new RegExp(`${kw}[^0-9]{0,15}(\\d+(?:[\\.,]\\d+)?)`, 'i');
        const match = lower.match(regex);
        if (match && match[1]) {
          return parseFloat(match[1].replace(',', '.'));
        }
      }
      return null;
    };

    const mapping = [
      { keys: ['cou', 'tour de cou'], field: 'cou' },
      { keys: ['epaule', 'épaules', 'largeur epaule'], field: 'epaule' },
      { keys: ['poitrine', 'tour de poitrine', 'buste'], field: 'poitrine' },
      { keys: ['bras', 'longueur bras', 'manche'], field: 'longueurBras' },
      { keys: ['boubou', 'longueur boubou'], field: 'longueurBoubou' },
      { keys: ['taille', 'tour de taille'], field: 'taille' },
      { keys: ['bassin', 'hanche', 'hanches'], field: 'bassin' },
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
      message: `${Object.keys(measurements).length} mesure(s) extraite(s) par l'IA`,
    };
  }
}
