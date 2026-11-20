import { Test, TestingModule } from '@nestjs/testing';
import { AiMeasurementsService } from './ai-measurements.service';
import { ConfigService } from '@nestjs/config';

describe('AiMeasurementsService', () => {
  let service: AiMeasurementsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiMeasurementsService,
        { provide: ConfigService, useValue: {} },
      ],
    }).compile();

    service = module.get<AiMeasurementsService>(AiMeasurementsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('parseText', () => {
    it('should correctly parse measurements with accents and multi-word keys', () => {
      const transcript = 'cours 45, épaule 26, poitrine 25, longueur boubou 145, entre jambes 12';
      const result = service.parseText(transcript);

      expect(result.success).toBe(true);
      expect(result.data['cou']).toEqual(45);
      expect(result.data['epaule']).toEqual(26);
      expect(result.data['poitrine']).toEqual(25);
      expect(result.data['longueurBoubou']).toEqual(145);
      expect(result.data['entrejambe']).toEqual(12);
    });

    it('should handle speech typos like "cours" -> "cou"', () => {
      const transcript = 'cours 36';
      const result = service.parseText(transcript);

      expect(result.data['cou']).toEqual(36);
    });

    it('should handle Wolof numbers if present', () => {
      const transcript = 'poitrine teemeer';
      const result = service.parseText(transcript);

      expect(result.data['poitrine']).toEqual(100);
    });
  });
});
