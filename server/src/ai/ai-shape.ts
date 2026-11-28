/**
 * Minimal runtime shape checking for JSON returned by the LLM. Each field spec
 * is one of:
 *   'string' | 'number' | 'string|null' | 'number|null' | 'string[]'
 *   'enum:A|B|C'   (string, one of the listed values)
 *   'array'        (any array, items unchecked)
 * A trailing '?' makes the field optional.
 *
 * Numbers given as numeric strings ("12.50") are coerced, since models do that.
 */
export type FieldSpec = string;
export type ShapeSpec = Record<string, FieldSpec>;

export class ShapeError extends Error {}

export function checkShape<T>(value: unknown, spec: ShapeSpec): T {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ShapeError('AI response is not a JSON object');
  }
  const input = value as Record<string, unknown>;
  const out: Record<string, unknown> = { ...input };

  for (const [key, rawSpec] of Object.entries(spec)) {
    const optional = rawSpec.endsWith('?');
    const type = optional ? rawSpec.slice(0, -1) : rawSpec;
    const v = input[key];

    if (v === undefined || (optional && v === null)) {
      if (optional) {
        delete out[key]; // models send null for "not applicable"
        continue;
      }
      throw new ShapeError(`AI response is missing "${key}"`);
    }
    out[key] = checkField(key, v, type);
  }
  return out as T;
}

function checkField(key: string, v: unknown, type: string): unknown {
  const fail = () => {
    throw new ShapeError(`AI response field "${key}" is not ${type}`);
  };
  const nullable = type.endsWith('|null');
  const base = nullable ? type.slice(0, -5) : type;
  if (v === null) return nullable ? null : fail();

  if (base === 'string') return typeof v === 'string' ? v : fail();
  if (base === 'number') {
    const n = typeof v === 'string' && v.trim() !== '' ? Number(v) : v;
    return typeof n === 'number' && Number.isFinite(n) ? n : fail();
  }
  if (base === 'string[]') {
    return Array.isArray(v) && v.every((x) => typeof x === 'string')
      ? v
      : fail();
  }
  if (base === 'array') return Array.isArray(v) ? v : fail();
  if (base.startsWith('enum:')) {
    const allowed = base.slice(5).split('|');
    const s = typeof v === 'string' ? v.toUpperCase() : v;
    return typeof s === 'string' && allowed.includes(s) ? s : fail();
  }
  throw new Error(`Unknown field spec "${type}" for "${key}"`);
}

/** Human/LLM-readable description of the expected JSON, for the prompt. */
export function describeShape(spec: ShapeSpec): string {
  const lines = Object.entries(spec).map(([key, s]) => {
    const optional = s.endsWith('?');
    const t = (optional ? s.slice(0, -1) : s).replace(
      /^enum:(.*)$/,
      (_, v: string) =>
        `one of ${v
          .split('|')
          .map((x) => `"${x}"`)
          .join(', ')}`,
    );
    return `  "${key}": ${t}${optional ? ' (optional)' : ''}`;
  });
  return `Respond with a single JSON object with exactly these fields:\n{\n${lines.join(',\n')}\n}`;
}
