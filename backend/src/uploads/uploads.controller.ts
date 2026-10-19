import { Controller, Post, UseInterceptors, UploadedFile, Get, Param, Res, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiConsumes, ApiBody, ApiOperation } from '@nestjs/swagger';
import { UploadsService } from './uploads.service';
import { Public } from '../common/decorators/public.decorator';
import { Response } from 'express';
import * as path from 'path';
import * as fs from 'fs';

@ApiTags('uploads')
@Controller('uploads')
export class UploadsController {
  constructor(private uploadsService: UploadsService) {}

  @Post('image')
  @ApiOperation({ summary: 'Téléverser une image (photo produit ou avatar)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @UseInterceptors(FileInterceptor('file'))
  uploadImage(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Aucun fichier image fourni');
    return this.uploadsService.uploadImage(file);
  }

  @Public()
  @Get(':filename')
  @ApiOperation({ summary: 'Servir une image locale' })
  serveImage(@Param('filename') filename: string, @Res() res: Response) {
    const filePath = path.join(process.cwd(), 'uploads', filename);
    if (!fs.existsSync(filePath)) {
      return res.status(404).send('Image non trouvée');
    }
    return res.sendFile(filePath);
  }
}
