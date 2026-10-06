import {
  Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ClientsService, CreateCustomerDto } from './clients.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('artisans')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ARTISAN')
@Controller('artisans/customers')
export class ClientsController {
  constructor(private clientsService: ClientsService) {}

  @Get()
  @ApiOperation({ summary: 'Carnet clients de l\'artisan' })
  @ApiQuery({ name: 'search', required: false })
  findAll(
    @CurrentUser('artisanId') artisanId: string,
    @Query('search') search?: string,
  ) {
    return this.clientsService.findAll(artisanId, search);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Fiche détail client avec historique commandes' })
  findOne(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.clientsService.findOne(artisanId, id);
  }

  @Post()
  @ApiOperation({ summary: 'Ajouter un client au carnet' })
  create(@CurrentUser('artisanId') artisanId: string, @Body() dto: CreateCustomerDto) {
    return this.clientsService.create(artisanId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Modifier un client' })
  update(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() dto: Partial<CreateCustomerDto>,
  ) {
    return this.clientsService.update(artisanId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer un client et ses commandes associées' })
  remove(@CurrentUser('artisanId') artisanId: string, @Param('id') id: string) {
    return this.clientsService.remove(artisanId, id);
  }

  @Patch(':id/measurements')
  @ApiOperation({ summary: 'Mettre à jour les mesures corporelles d\'un client' })
  updateMeasurements(
    @CurrentUser('artisanId') artisanId: string,
    @Param('id') id: string,
    @Body() measurements: Record<string, any>,
  ) {
    return this.clientsService.updateMeasurements(artisanId, id, measurements);
  }
}
