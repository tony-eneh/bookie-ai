import { Injectable, Logger, NotFoundException } from '@nestjs/common';
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
    throw new NotFoundException(
      `Exchange rate not available for ${baseCurrency}/${targetCurrency}`,
    );
  }

  /**
   * Loads the rates for the given (from, to) pairs once, so many amounts can
   * be converted synchronously. A missing rate leaves amounts unconverted
   * (logged) rather than failing the caller.
   */
  async loadConverter(
    pairs: Iterable<[string, string]>,
  ): Promise<(amount: number, from: string, to: string) => number> {
    const rates = new Map<string, number>();
    const wanted = new Set<string>();
    for (const [from, to] of pairs) {
      if (from && to && from !== to) wanted.add(`${from}>${to}`);
    }
    await Promise.all(
      [...wanted].map(async (key) => {
        const [from, to] = key.split('>');
        try {
          rates.set(key, await this.getRate(from, to));
        } catch {
          this.logger.warn(`No FX rate for ${from}->${to}; left unconverted`);
        }
      }),
    );
    return (amount, from, to) =>
      !from || from === to ? amount : amount * (rates.get(`${from}>${to}`) ?? 1);
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

  /**
   * exchangerate-api.com wants the base in the path (/v4/latest/USD); with
   * ?base= it redirects to an HTML page. Use {base} in FX_API_URL for
   * providers with another shape; otherwise the base is appended.
   */
  static ratesUrl(apiUrl: string, base: string): string {
    if (apiUrl.includes('{base}')) return apiUrl.replace('{base}', base);
    return `${apiUrl.replace(/\/+$/, '')}/${encodeURIComponent(base)}`;
  }

  async fetchRates(baseCurrency: string): Promise<void> {
    const apiUrl = this.config.get<string>('FX_API_URL');
    if (!apiUrl) {
      this.logger.warn('FX_API_URL not configured, using cached rates only');
      return;
    }

    try {
      const url = FxRatesService.ratesUrl(apiUrl, baseCurrency);
      const response = await fetch(url, { signal: AbortSignal.timeout(10_000) });

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

      const entries = Object.entries(rates).filter(
        ([code, rate]) => /^[A-Z]{3}$/.test(code) && Number.isFinite(rate),
      );
      const targets = entries.map(([code]) => code);
      const values = entries.map(([, rate]) => rate);

      // One statement instead of ~160 parallel upserts.
      await this.prisma.$executeRaw`
        INSERT INTO fx_rates (id, base_currency, target_currency, rate, source, fetched_at)
        SELECT gen_random_uuid(), ${baseCurrency}, t, r, 'api', ${now}
        FROM unnest(${targets}::text[], ${values}::numeric[]) AS x(t, r)
        ON CONFLICT (base_currency, target_currency)
        DO UPDATE SET rate = EXCLUDED.rate, source = 'api', fetched_at = EXCLUDED.fetched_at`;
      this.logger.log(`Fetched ${entries.length} rates for base ${baseCurrency}`);
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
