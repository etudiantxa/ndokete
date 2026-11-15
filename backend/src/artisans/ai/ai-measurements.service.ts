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
      longueurBras: ['bras', 'longueur bras', 'manche', 'longueur manche', 'loxo', 'm'],
      longueurBoubou: ['boubou', 'longueur boubou', 'manteau', 'grand boubou', 'longueur du boubou'],
      taille: ['taille', 'tour de taille', 'biir', 't'],
      bassin: ['bassin', 'hanche', 'hanches', 'gon', 'bass'],
      longPantalon: ['pantalon', 'longueur pantalon', 'jupe', 'longueur jupe', 'longueurs pantalon', 'longueur zip', 'zip', 'pant'],
      entrejambe: ['entrejambe', 'entre jambes', 'entre jambe', 'jambe'],
      pointure: ['pointure', 'pointure chaussures', 'pied', 'point'],
    };

    const words = cleanText.split(/\s+/).filter(w => w.length > 0);

    // Algorithme d'analyse contextuelle et de proximité (Tokenisation & Proximity Matcher)
    for (let i = 0; i < words.length; i++) {
      const num = parseFloat(words[i]);
      if (!isNaN(num)) {
        // Chercher dans les 3 mots précédents le mot-clé de mesure le plus proche
        let matchedField: string | null = null;
        for (let j = Math.max(0, i - 3); j < i; j++) {
          const candidateWord = words[j];
          for (const [field, keys] of Object.entries(synonyms)) {
            if (keys.some(k => candidateWord.includes(k) || k.includes(candidateWord))) {
              matchedField = field;
              break;
            }
          }
          if (matchedField) break;
        }

        // Si aucun mot-clé immédiat n'est trouvé en amont, on peut aussi l'associer séquentiellement ou par ordre d'apparition si pertinent
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
