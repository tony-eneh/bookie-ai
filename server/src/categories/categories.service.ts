import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateCategoryDto } from './dto/create-category.dto.js';
import { UpdateCategoryDto } from './dto/update-category.dto.js';
import type { TransactionType } from '../../generated/prisma/client.js';

interface DefaultCategory {
  name: string;
  type: TransactionType;
  icon: string;
}

const DEFAULT_CATEGORIES: DefaultCategory[] = [
  // EXPENSE
  { name: 'Food & Dining', type: 'EXPENSE', icon: '🍔' },
  { name: 'Groceries', type: 'EXPENSE', icon: '🛒' },
  { name: 'Transport', type: 'EXPENSE', icon: '🚗' },
  { name: 'Fuel', type: 'EXPENSE', icon: '⛽' },
  { name: 'Rent', type: 'EXPENSE', icon: '🏠' },
  { name: 'Utilities', type: 'EXPENSE', icon: '💡' },
  { name: 'Internet', type: 'EXPENSE', icon: '🌐' },
  { name: 'Mobile/Data', type: 'EXPENSE', icon: '📱' },
  { name: 'Healthcare', type: 'EXPENSE', icon: '🏥' },
  { name: 'Education', type: 'EXPENSE', icon: '📚' },
  { name: 'Shopping', type: 'EXPENSE', icon: '🛍️' },
  { name: 'Entertainment', type: 'EXPENSE', icon: '🎬' },
  { name: 'Subscriptions', type: 'EXPENSE', icon: '📺' },
  { name: 'Savings', type: 'EXPENSE', icon: '💰' },
  { name: 'Debt Repayment', type: 'EXPENSE', icon: '💳' },
  { name: 'Gifts/Donations', type: 'EXPENSE', icon: '🎁' },
  { name: 'Family Support', type: 'EXPENSE', icon: '👨‍👩‍👧' },
  { name: 'Business Expense', type: 'EXPENSE', icon: '💼' },
  { name: 'Travel', type: 'EXPENSE', icon: '✈️' },
  { name: 'Miscellaneous', type: 'EXPENSE', icon: '📦' },
  // INCOME
  { name: 'Salary', type: 'INCOME', icon: '💵' },
  { name: 'Freelance', type: 'INCOME', icon: '💻' },
  { name: 'Business Income', type: 'INCOME', icon: '🏢' },
  { name: 'Gift Received', type: 'INCOME', icon: '🎀' },
  { name: 'Refund', type: 'INCOME', icon: '↩️' },
  { name: 'Loan Received', type: 'INCOME', icon: '🏦' },
  { name: 'Repayment Received', type: 'INCOME', icon: '🤝' },
  { name: 'Investment Income', type: 'INCOME', icon: '📈' },
  { name: 'Miscellaneous Income', type: 'INCOME', icon: '💫' },
  // TRANSFER
  { name: 'Internal Transfer', type: 'TRANSFER', icon: '🔄' },
  { name: 'Savings Transfer', type: 'TRANSFER', icon: '🏦' },
  { name: 'Wallet Funding', type: 'TRANSFER', icon: '📲' },
  { name: 'Bank Transfer', type: 'TRANSFER', icon: '🏛️' },
];

@Injectable()
export class CategoriesService implements OnModuleInit {
  private readonly logger = new Logger(CategoriesService.name);

  constructor(private prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedDefaults();
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

  async seedDefaults() {
    const count = await this.prisma.category.count({
      where: { isDefault: true },
    });

    if (count > 0) {
      this.logger.log('Default categories already seeded');
      return;
    }

    this.logger.log('Seeding default categories...');

    await this.prisma.category.createMany({
      data: DEFAULT_CATEGORIES.map((cat) => ({
        name: cat.name,
        type: cat.type,
        icon: cat.icon,
        isDefault: true,
      })),
    });

    this.logger.log(`Seeded ${DEFAULT_CATEGORIES.length} default categories`);
  }
}
