import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { DEFAULT_CATEGORIES } from './default-categories.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCategoryDto } from './dto/create-category.dto.js';
import { UpdateCategoryDto } from './dto/update-category.dto.js';

@Injectable()
export class CategoriesService implements OnApplicationBootstrap {
  private readonly logger = new Logger(CategoriesService.name);

  constructor(private prisma: PrismaService) {}

  async onApplicationBootstrap() {
    try {
      const created = await this.ensureDefaultCategories();
      if (created > 0) {
        this.logger.log(`Created ${created} missing default categories`);
      }
    } catch (error) {
      // Don't take the API down over this; it's retried on the next boot.
      this.logger.error(
        `Could not ensure default categories: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  /**
   * Creates any built-in categories that are missing. Idempotent and safe to
   * run from several instances at once (serialized by an advisory lock).
   * Returns how many were created.
   */
  async ensureDefaultCategories(): Promise<number> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('bookie:default-categories'))`;
      const existing = await tx.category.findMany({
        where: { isDefault: true, userId: null },
        select: { name: true, type: true },
      });
      const have = new Set(existing.map((c) => `${c.type}:${c.name}`));
      const missing = DEFAULT_CATEGORIES.filter(
        (c) => !have.has(`${c.type}:${c.name}`),
      );
      if (missing.length > 0) {
        await tx.category.createMany({
          data: missing.map((c) => ({ ...c, isDefault: true })),
        });
      }
      return missing.length;
    });
  }

  async findAll(userId: string) {
    return this.prisma.category.findMany({
      where: {
        OR: [{ userId }, { isDefault: true }],
      },
      orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    });
  }

  async findById(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) {
      throw new NotFoundException('Category not found');
    }
    return category;
  }

  async create(userId: string, dto: CreateCategoryDto) {
    return this.prisma.category.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        icon: dto.icon ?? '📦',
        color: dto.color,
        isDefault: false,
      },
    });
  }

  async update(id: string, userId: string, dto: UpdateCategoryDto) {
    const category = await this.findById(id);

    if (category.isDefault || category.userId !== userId) {
      throw new ForbiddenException('Cannot modify this category');
    }

    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.icon !== undefined) data.icon = dto.icon;
    if (dto.color !== undefined) data.color = dto.color;

    return this.prisma.category.update({
      where: { id },
      data,
    });
  }

  async delete(id: string, userId: string) {
    const category = await this.findById(id);

    if (category.isDefault || category.userId !== userId) {
      throw new ForbiddenException('Cannot delete this category');
    }

    return this.prisma.category.delete({ where: { id } });
  }
}
