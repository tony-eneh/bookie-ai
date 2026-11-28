/**
 * Parses bank statement CSV exports into transaction rows. Handles the
 * common shapes: a single signed "Amount" column, or separate Debit/Credit
 * (Withdrawal/Deposit) columns; quoted fields; comma or semicolon
 * delimiters; ISO, DD/MM/YYYY and "05 Nov 2026" dates; "1,234.50", "(500)"
 * and "500 DR" amounts.
 */
export interface StatementRow {
  type: 'INCOME' | 'EXPENSE';
  amount: number;
  occurredAt: string;
  description: string;
}

export interface ParsedStatement {
  rows: StatementRow[];
  skippedLines: number;
}

const HEADER = {
  date: /^(transaction |trans\.? |posting |value |txn )?date$|^date posted$/,
  description: /^(description|narration|details|remarks|particulars|memo|transaction details|payee)$/,
  amount: /^(amount|transaction amount|amt)$/,
  debit: /^(debit|debits|withdrawal|withdrawals|money out|paid out|dr)( amount)?$/,
  credit: /^(credit|credits|deposit|deposits|money in|paid in|cr)( amount)?$/,
};

const MONTHS: Record<string, number> = {
  jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5,
  jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11,
};

export function splitCsvLine(line: string, delimiter: string): string[] {
  const cells: string[] = [];
  let cell = '';
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (quoted) {
      if (ch === '"' && line[i + 1] === '"') {
        cell += '"';
        i++;
      } else if (ch === '"') {
        quoted = false;
      } else {
        cell += ch;
      }
    } else if (ch === '"') {
      quoted = true;
    } else if (ch === delimiter) {
      cells.push(cell.trim());
      cell = '';
    } else {
      cell += ch;
    }
  }
  cells.push(cell.trim());
  return cells;
}

/** Signed amount; null when the cell is empty or not a number. */
export function parseAmount(raw: string | undefined): number | null {
  if (!raw) return null;
  let s = raw.trim().toUpperCase();
  if (!s) return null;
  let sign = 1;
  if (/^\(.*\)$/.test(s)) {
    sign = -1;
    s = s.slice(1, -1);
  }
  if (/\bDR\.?$/.test(s)) {
    sign = -1;
    s = s.replace(/\bDR\.?$/, '');
  }
  s = s.replace(/\bCR\.?$/, '');
  if (s.startsWith('-')) {
    sign *= -1;
    s = s.slice(1);
  }
  s = s.replace(/[^\d.]/g, '');
  if (!s || Number.isNaN(Number(s))) return null;
  return sign * Number(s);
}

/** ISO date string, or null. Ambiguous a/b/yyyy is read as day/month. */
export function parseDate(raw: string | undefined): string | null {
  if (!raw) return null;
  const s = raw.trim();
  let y: number, m: number, d: number;
  let match = s.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})/);
  if (match) {
    [y, m, d] = [Number(match[1]), Number(match[2]) - 1, Number(match[3])];
  } else if ((match = s.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})/))) {
    let a = Number(match[1]);
    let b = Number(match[2]);
    if (b > 12 && a <= 12) [a, b] = [b, a]; // clearly month/day
    d = a;
    m = b - 1;
    y = Number(match[3]);
  } else if ((match = s.match(/^(\d{1,2})[-\s]([A-Za-z]{3})[A-Za-z]*[-\s,]+(\d{2,4})/))) {
    d = Number(match[1]);
    m = MONTHS[match[2].toLowerCase()] ?? -1;
    y = Number(match[3]);
  } else {
    return null;
  }
  if (y < 100) y += 2000;
  if (m < 0 || m > 11 || d < 1 || d > 31) return null;
  const date = new Date(Date.UTC(y, m, d, 12));
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function parseStatementCsv(text: string): ParsedStatement {
  const lines = text
    .replace(/^﻿/, '')
    .split(/\r?\n/)
    .filter((l) => l.trim().length > 0);
  // Banks often put account info above the table: find the header row.
  let headerIndex = -1;
  let delimiter = ',';
  let cols: Record<keyof typeof HEADER, number> | null = null;
  for (let i = 0; i < Math.min(lines.length, 25) && !cols; i++) {
    for (const delim of [',', ';', '\t']) {
      const cells = splitCsvLine(lines[i], delim).map((c) => c.toLowerCase());
      const find = (re: RegExp) => cells.findIndex((c) => re.test(c));
      const found = {
        date: find(HEADER.date),
        description: find(HEADER.description),
        amount: find(HEADER.amount),
        debit: find(HEADER.debit),
        credit: find(HEADER.credit),
      };
      if (
        found.date >= 0 &&
        found.description >= 0 &&
        (found.amount >= 0 || (found.debit >= 0 && found.credit >= 0))
      ) {
        cols = found;
        headerIndex = i;
        delimiter = delim;
        break;
      }
    }
  }
  if (!cols) {
    throw new Error(
      'Could not find the column headers. The file needs Date, Description and either Amount or Debit/Credit columns.',
    );
  }

  const rows: StatementRow[] = [];
  let skippedLines = 0;
  for (const line of lines.slice(headerIndex + 1)) {
    const cells = splitCsvLine(line, delimiter);
    const occurredAt = parseDate(cells[cols.date]);
    const description = cells[cols.description]?.trim();
    let signed: number | null;
    if (cols.debit >= 0 && cols.credit >= 0) {
      const debit = parseAmount(cells[cols.debit]);
      const credit = parseAmount(cells[cols.credit]);
      signed = debit ? -Math.abs(debit) : credit ? Math.abs(credit) : null;
    } else {
      signed = parseAmount(cells[cols.amount]);
    }
    if (!occurredAt || !description || !signed) {
      skippedLines++; // totals, opening balance, blank rows
      continue;
    }
    rows.push({
      type: signed < 0 ? 'EXPENSE' : 'INCOME',
      amount: Math.abs(signed),
      occurredAt,
      description,
    });
  }
  return { rows, skippedLines };
}
