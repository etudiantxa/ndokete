import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { v2 as cloudinary } from 'cloudinary';

@Injectable()
export class UploadsService {
  private readonly logger = new Logger(UploadsService.name);

  constructor(private config: ConfigService) {
    const cloudName = this.config.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.config.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.config.get<string>('CLOUDINARY_API_SECRET');

    if (cloudName && cloudName !== 'your_cloud_name') {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      this.logger.log('Cloudinary configuré pour le téléversement d\'images');
    }
  }

  async uploadImage(file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('Fichier image requis');
    }

    const cloudName = this.config.get<string>('CLOUDINARY_CLOUD_NAME');

    // Si Cloudinary est configuré
    if (cloudName && cloudName !== 'your_cloud_name') {
      try {
        const result = await new Promise<any>((resolve, reject) => {
          const uploadStream = cloudinary.uploader.upload_stream(
            { folder: 'ndokete_uploads' },
            (error, result) => {
              if (error) return reject(error);
              resolve(result);
            },
          );
          uploadStream.end(file.buffer);
        });

        return {
          success: true,
          url: result.secure_url,
          message: 'Image téléversée sur Cloudinary avec succès',
        };
      } catch (err) {
        this.logger.error('Erreur Cloudinary, bascule sur le stockage local', err);
      }
    }

    // Stockage local
    const uploadsDir = path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    const ext = path.extname(file.originalname) || '.jpg';
    const filename = `img_${Date.now()}_${Math.random().toString(36).substr(2, 6)}${ext}`;
    const filePath = path.join(uploadsDir, filename);

    fs.writeFileSync(filePath, file.buffer);

    const appUrl = this.config.get<string>('APP_URL') || 'http://localhost:3000';
    const localUrl = `${appUrl}/api/v1/uploads/${filename}`;

    return {
      success: true,
      url: localUrl,
      message: 'Image téléversée avec succès',
    };
  }
}
