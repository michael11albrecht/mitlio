// schema.org structured data (PW-T08). Pure builders; tool/seo_check.mjs validates the built output.
const CONTEXT = 'https://schema.org';

export const organization = (siteUrl: string) => ({
  '@context': CONTEXT,
  '@type': 'Organization',
  name: 'mitlio',
  url: siteUrl,
});

export const webApplication = (o: { name: string; url: string; description: string; lang: string }) => ({
  '@context': CONTEXT,
  '@type': 'WebApplication',
  name: o.name,
  url: o.url,
  description: o.description,
  inLanguage: o.lang,
  applicationCategory: 'UtilitiesApplication',
  operatingSystem: 'Any',
  browserRequirements: 'Requires JavaScript',
  offers: { '@type': 'Offer', price: '0', priceCurrency: 'EUR' },
});

export const faqPage = (items: { q: string; a: string }[]) => ({
  '@context': CONTEXT,
  '@type': 'FAQPage',
  mainEntity: items.map(({ q, a }) => ({
    '@type': 'Question',
    name: q,
    acceptedAnswer: { '@type': 'Answer', text: a },
  })),
});

export const howTo = (o: { name: string; steps: { name: string; text: string }[] }) => ({
  '@context': CONTEXT,
  '@type': 'HowTo',
  name: o.name,
  step: o.steps.map((s, i) => ({ '@type': 'HowToStep', position: i + 1, name: s.name, text: s.text })),
});
