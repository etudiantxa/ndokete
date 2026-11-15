import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AiMeasurementsService {
  constructor(private config: ConfigService) {}

  parseText(text: string) {
    const measurements: Record<string, number> = {};
    let cleanText = text.toLowerCase();

    // Normaliser les accents et la ponctuation
    cleanText = cleanText
      .replace(/[éèêë]/g, 'e')
      .replace(/[àâä]/g, 'a')
      .replace(/[îï]/g, 'i')
      .replace(/[ôö]/g, 'o')
      .replace(/[ùûü]/g, 'u')
      .replace(/ç/g, 'c')
      .replace(/[\.,\/#!$%\^&\*;:{}=\-_`~()?]/g, ' ');

    // Corrections de dictée vocale courantes en atelier (ex: "cours" -> "cou")
    cleanText = cleanText.replace(/\bcours\b/g, 'cou');

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

    // Dictionnaire de synonymes enrichi (tolérant aux variations phonétiques et au jargon d'atelier)
    const synonyms: Record<string, string[]> = {
      cou: ['cou', 'cours', 'col', 'kow', 'tour de cou'],
      epaule: ['epaule', 'epaules', 'epole', 'epol', 'baari', 'epau'],
      poitrine: ['poitrine', 'poitrin', 'buste', 'potrin', 'poitrn', 'poitr'],
      longueurBras: ['bras', 'longueur bras', 'longueur du bras', 'manche', 'longueur manche', 'loxo', 'm'],
      longueurBoubou: ['boubou', 'longueur boubou', 'manteau', 'grand boubou', 'longueur du boubou', 'longueur boubou'],
      taille: ['taille', 'tour de taille', 'biir', 't'],
      bassin: ['bassin', 'hanche', 'hanches', 'gon', 'bass'],
      longPantalon: ['pantalon', 'longueur pantalon', 'jupe', 'longueur jupe', 'longueurs pantalon', 'longueur zip', 'zip', 'pant', 'longueurs pantalon'],
      entrejambe: ['entrejambe', 'entre jambes', 'entre jambe', 'jambe'],
      pointure: ['pointure', 'pointure chaussures', 'pied', 'point'],
    };

    // Aplatir et trier les synonymes par longueur décroissante (les expressions composées en premier pour éviter que "longueur" ne vole la vedette à "longueur boubou")
    const allKeyEntries: { field: string; key: string }[] = [];
    for (const [field, keys] of Object.entries(synonyms)) {
      for (const k of keys) {
        allKeyEntries.push({ field, key: k });
      }
    }
    allKeyEntries.sort((a, b) => b.key.length - a.key.length);

    const words = cleanText.split(/\s+/).filter(w => w.length > 0);

    for (let i = 0; i < words.length; i++) {
      const num = parseFloat(words[i]);
      if (!isNaN(num)) {
        const precedingPhrase = words.slice(Math.max(0, i - 3), i).join(' ');
        const precedingWord = i > 0 ? words[i - 1] : '';

        let matchedField: string | null = null;

        // 1. Tester en priorité les expressions composées en amont (ex: "longueur boubou", "entre jambes")
        for (const entry of allKeyEntries) {
          if (entry.key.includes(' ') && precedingPhrase.includes(entry.key)) {
            matchedField = entry.field;
            break;
          }
        }

        // 2. Si pas trouvé, tester le mot ou l'expression immédiate
        if (!matchedField) {
          for (const entry of allKeyEntries) {
            if (precedingPhrase.includes(entry.key) || precedingWord.includes(entry.key)) {
              matchedField = entry.field;
              break;
            }
          }
        }

        if (matchedField && !measurements[matchedField]) {
          measurements[matchedField] = num;
        }
      }
    }

    return {
      success: true,
      data: measurements,
      message: `${Object.keys(measurements).length} mesure(s) extraite(s) par l'IA contextuelle d'atelier`,
    };
  }
}
