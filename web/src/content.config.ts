import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

// One markdown file per landing page (PW-T07). The owner edits copy in src/content/landing/*.md.
// Numbers in the worked example and FAQ answers are placeholders ({total}, {perPerson}, ...)
// that are filled at build time from the domain facade, so the copy can never drift from the maths.
const landingSchema = z.object({
  /** <title>, max 60 characters. */
  title: z.string().max(60),
  /** <meta name="description">, max 155 characters. */
  description: z.string().max(155),
  h1: z.string(),
  lead: z.string(),
  /** Link text in the "more calculators" list. */
  linkLabel: z.string(),
  /** Km-rate mode: the calculator asks for EUR per km instead of consumption and price. */
  rate: z.boolean().default(false),
  /** Worked example. Also the calculator preset, so the page shows exactly the numbers it explains. */
  example: z.object({
    input: z.object({
      distanceKm: z.number(),
      consumptionPer100km: z.number().optional(),
      pricePerUnit: z.number().optional(),
      kmRate: z.number().optional(),
      persons: z.number(),
      driverPays: z.boolean().default(true),
      roundTrip: z.boolean().default(false),
      tollsEur: z.number().optional(),
      ev: z.boolean().default(false),
    }),
    /** Optional second scenario: these fields override `input` (placeholders get a "2" suffix). */
    compare: z
      .object({
        persons: z.number().optional(),
        driverPays: z.boolean().optional(),
        roundTrip: z.boolean().optional(),
        tollsEur: z.number().optional(),
      })
      .optional(),
    /** Paragraphs separated by blank lines. Placeholders: see src/lib/landing.ts. */
    text: z.string(),
  }),
  howto: z
    .object({
      name: z.string(),
      steps: z.array(z.object({ name: z.string(), text: z.string() })).min(2),
    })
    .optional(),
  faq: z.array(z.object({ q: z.string(), a: z.string() })).min(4).max(6),
  /** Slugs of sibling pages to link to. */
  related: z.array(z.string()).min(2),
});

const landing = defineCollection({
  loader: glob({ pattern: '*.md', base: './src/content/landing' }),
  schema: landingSchema,
});

// English equivalents (PW-T07 EN): same schema, written for English search intent rather than translated.
// `de` is the slug of the German counterpart; both pages link each other with hreflang.
const landingEn = defineCollection({
  loader: glob({ pattern: '*.md', base: './src/content/landing-en' }),
  schema: landingSchema.extend({ de: z.string() }),
});

export const collections = { landing, landingEn };
