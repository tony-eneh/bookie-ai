import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';

const CACHE_MAX_AGE_MS = 6 * 60 * 60 * 1000; // 6 hours

@Injectable()
export class FxRatesService {
  private readonly logger = new Logger(FxRatesService.name);

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {}

  async getRate(baseCurrency: string, targetCurrency: string): Promise<number> {
    if (baseCurrency === targetCurrency) return 1;

    const cached = await this.prisma.fxRate.findUnique({
      where: {
        baseCurrency_targetCurrency: { baseCurrency, targetCurrency },
      },
    });

    if (cached) {
      const age = Date.now() - cached.fetchedAt.getTime();
      if (age < CACHE_MAX_AGE_MS) {
        return Number(cached.rate);
      }
    }

    // Cache miss or stale – fetch fresh rates
    await this.fetchRates(baseCurrency);

    const fresh = await this.prisma.fxRate.findUnique({
      where: {
        baseCurrency_targetCurrency: { baseCurrency, targetCurrency },
      },
    });

    if (fresh) return Number(fresh.rate);

    // If still no rate found after fetch, throw
    if (cached) return Number(cached.rate);
    throw new Error(
      `Exchange rate not available for ${baseCurrency}/${targetCurrency}`,
    );
  }

  async convert(
    amount: number,
    fromCurrency: string,
    toCurrency: string,
  ): Promise<{ convertedAmount: number; rate: number }> {
    const rate = await this.getRate(fromCurrency, toCurrency);
    return {
      convertedAmount: Number((amount * rate).toFixed(4)),
      rate,
    };
  }

  async fetchRates(baseCurrency: string): Promise<void> {
    const apiUrl = this.config.get<string>('FX_API_URL');
    if (!apiUrl) {
      this.logger.warn('FX_API_URL not configured, using cached rates only');
      return;
    }

    try {
      const url = `${apiUrl}?base=${baseCurrency}`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`FX API responded with status ${response.status}`);
      }

      const data = (await response.json()) as {
        rates?: Record<string, number>;
      };
      const rates = data.rates;

      if (!rates || typeof rates !== 'object') {
        throw new Error('Invalid response format from FX API');
      }

      const now = new Date();

      const upserts = Object.entries(rates).map(
        ([targetCurrency, rate]) =>
          this.prisma.fxRate.upsert({
            where: {
              baseCurrency_targetCurrency: { baseCurrency, targetCurrency },
            },
            update: { rate, source: 'api', fetchedAt: now },
            create: {
              baseCurrency,
              targetCurrency,
              rate,
              source: 'api',
              fetchedAt: now,
            },
          }),
      );

      await Promise.all(upserts);
      this.logger.log(
        `Fetched ${upserts.length} rates for base ${baseCurrency}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to fetch FX rates for ${baseCurrency}, falling back to cached rates`,
        error instanceof Error ? error.message : error,
      );
    }
  }

  async getLatestRates() {
    return this.prisma.fxRate.findMany({
      orderBy: { fetchedAt: 'desc' },
    });
  }

  async getAllRatesForCurrency(currency: string) {
    return this.prisma.fxRate.findMany({
      where: { baseCurrency: currency },
      orderBy: { targetCurrency: 'asc' },
    });
  }
}
