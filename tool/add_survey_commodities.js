const fs = require('fs');
const path = require('path');

// Adds the 5 Oct 2026 market survey commodities that are not yet in Firestore,
// so samples/lingayen_market_monitoring_2026-10-14_fixed.csv imports cleanly.
// Safe to re-run: existing categories and commodities (matched by name) are kept.
//
// PRICEWATCH_ADMIN_EMAIL=... PRICEWATCH_ADMIN_PASSWORD=... node tool/add_survey_commodities.js [--dry-run]

const root = path.resolve(__dirname, '..');
const firebaseOptions = fs.readFileSync(
  path.join(root, 'lib/firebase_options.dart'),
  'utf8',
);

const readAdminCredential = (name) => {
  const value = process.env[`PRICEWATCH_ADMIN_${name}`];
  if (!value) throw new Error(`Set PRICEWATCH_ADMIN_${name} to run this tool.`);
  return value;
};

const apiKey = firebaseOptions.match(/apiKey:\s*'([^']+)'/)?.[1];
if (!apiKey) throw new Error('Could not read the Firebase API key.');

const projectId = 'pricewatch-apk';
const databaseRoot =
  `https://firestore.googleapis.com/v1/projects/${projectId}` +
  '/databases/(default)/documents';
const dryRun = process.argv.includes('--dry-run');

// Existing subcategory ids (see the subcategories collection).
const SUB = {
  premium: 1791772127463000,
  regularMilled: 1791772132962000,
  tuna: 7213500839295191,
  highland: 7709751871466575,
  spices: 7562542183140153,
};

// Categories that must exist; existing ones are matched by name.
const CATEGORIES = [
  {name: 'Rice', icon: 'rice'},
  {name: 'Fish', icon: 'fish'},
  {name: 'Vegetables', icon: 'vegetables'},
  {name: 'Fruits', icon: 'vegetables'},
  {name: 'Sugar', icon: 'sugar'},
  {name: 'Cooking Oil', icon: 'oil'},
];

// [category, subcategory id, name, unit, prices recorded on the 5 Oct 2026 sheet]
const COMMODITIES = [
  ['Rice', SUB.premium, 'Local Premium Rice (Yellow tag)', 'kg', [56, 54, 55]],
  ['Rice', SUB.regularMilled, 'Local Regular Milled Rice (White tag)', 'kg', [37]],
  ['Fish', SUB.tuna, 'Bonito', 'kg', [180, 180, 180, 180, 180]],
  ['Fish', null, 'Sardines (Tamban)', 'kg', [400, 400]],
  ['Vegetables', SUB.highland, 'Bell Pepper (Green)', 'kg', [120, 160, 140]],
  ['Vegetables', SUB.highland, 'Bell Pepper (Red)', 'kg', [120, 160, 160]],
  ['Vegetables', SUB.highland, 'Cabbage (Wonder Ball)', 'kg', [150, 160, 140, 160, 150]],
  ['Vegetables', SUB.highland, 'Carrots', 'kg', [100, 110, 110, 110, 110]],
  ['Vegetables', SUB.highland, 'Cauliflower', 'kg', [240, 360]],
  ['Vegetables', SUB.highland, 'Habichuelas (Baguio Beans)', 'kg', [120, 160, 120, 160, 120]],
  ['Vegetables', SUB.spices, 'Ginger', 'kg', [140, 170, 170, 110, 160]],
  ['Fruits', null, 'Calamansi', 'kg', [70, 80, 80, 70, 70]],
  ['Fruits', null, 'Banana (Lakatan)', 'kg', [90, 90, 90, 90, 90]],
  ['Fruits', null, 'Banana (Latundan)', 'kg', [80, 60, 70]],
  ['Fruits', null, 'Banana (Saba)', 'kg', [70, 60, 50, 50, 60]],
  ['Fruits', null, 'Mango Carabao (Ripe)', 'kg', [280, 270]],
  ['Fruits', null, 'Mango Carabao (Green)', 'kg', [280, 270]],
  ['Fruits', null, 'Watermelon', 'kg', [70, 80, 80, 70, 60]],
  ['Sugar', null, 'Sugar (Refined)', 'kg', [80, 80, 80, 80, 80]],
  ['Sugar', null, 'Sugar (Washed)', 'kg', [75, 80, 75, 80, 75]],
  ['Sugar', null, 'Sugar (Brown)', 'kg', [70, 70, 70, 70, 70]],
  ['Cooking Oil', null, 'Cooking Oil (Palm) 350ml', '350 ml bottle', [38, 40, 40, 38, 38]],
  ['Cooking Oil', null, 'Cooking Oil (Palm) 1L', '1 L bottle', [85, 85, 85, 85, 85]],
  ['Cooking Oil', null, 'Cooking Oil (Coconut) 350ml', '350 ml bottle', [60, 60, 60, 60, 60]],
  ['Cooking Oil', null, 'Cooking Oil (Coconut) 1L', '1 L bottle', [150, 150, 150, 150, 150]],
];

const DESCRIPTION =
  'Added from the 5 Oct 2026 market survey. SRP set to the survey average ' +
  'until an official SRP is entered.';

const decodeValue = (value) => {
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return value.booleanValue;
  if ('nullValue' in value) return null;
  return value.stringValue ?? null;
};

const decodeDocument = (document) =>
  Object.fromEntries(
    Object.entries(document.fields ?? {}).map(([key, value]) => [
      key,
      decodeValue(value),
    ]),
  );

const encodeValue = (value) => {
  if (value === null) return {nullValue: null};
  if (Number.isInteger(value)) return {integerValue: String(value)};
  if (typeof value === 'number') return {doubleValue: value};
  return {stringValue: String(value)};
};

const listCollection = async (collection, token) => {
  const rows = [];
  let pageToken = '';
  do {
    const url = new URL(`${databaseRoot}/${collection}`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const response = await fetch(url, {
      headers: {Authorization: `Bearer ${token}`},
    });
    if (!response.ok) {
      throw new Error(`${collection} read failed: ${await response.text()}`);
    }
    const body = await response.json();
    rows.push(...(body.documents ?? []).map(decodeDocument));
    pageToken = body.nextPageToken ?? '';
  } while (pageToken);
  return rows;
};

const stableNumericId = (value) => {
  let hash = 1469598103934665603n;
  for (const character of value) {
    hash ^= BigInt(character.codePointAt(0));
    hash = BigInt.asUintN(64, hash * 1099511628211n);
  }
  return Number(7000000000000000n + (hash % 1000000000000000n));
};

const roundSrp = (prices) => {
  const average = prices.reduce((sum, price) => sum + price, 0) / prices.length;
  return Math.round(average);
};

const writeFor = (collection, id, fields) => ({
  update: {
    name: `projects/${projectId}/databases/(default)/documents/${collection}/${id}`,
    fields: Object.fromEntries(
      Object.entries(fields).map(([field, value]) => [field, encodeValue(value)]),
    ),
  },
  currentDocument: {exists: false},
});

async function main() {
  const authResponse = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: readAdminCredential('EMAIL'),
        password: readAdminCredential('PASSWORD'),
        returnSecureToken: true,
      }),
    },
  );
  if (!authResponse.ok) {
    throw new Error(`Admin sign-in failed: ${await authResponse.text()}`);
  }
  const token = (await authResponse.json()).idToken;
  const [categories, commodities] = await Promise.all([
    listCollection('categories', token),
    listCollection('commodities', token),
  ]);

  const now = new Date().toISOString();
  const writes = [];
  const categoryIds = new Map(
    categories.map((category) => [category.name.toLowerCase(), category.id]),
  );
  let nextCategoryId = Math.max(0, ...categories.map((c) => Number(c.id) || 0)) + 1;
  for (const category of CATEGORIES) {
    if (categoryIds.has(category.name.toLowerCase())) continue;
    const id = nextCategoryId++;
    categoryIds.set(category.name.toLowerCase(), id);
    writes.push(writeFor('categories', id, {id, name: category.name, icon: category.icon, created_at: now}));
    console.log(`+ category ${category.name} (${id})`);
  }

  const existingNames = new Set(commodities.map((c) => String(c.name).trim().toLowerCase()));
  let skipped = 0;
  for (const [category, subcategoryId, name, unit, prices] of COMMODITIES) {
    if (existingNames.has(name.toLowerCase())) {
      skipped++;
      continue;
    }
    const id = stableNumericId(`survey-2026-10-05:${name}`);
    const srp = roundSrp(prices);
    writes.push(
      writeFor('commodities', id, {
        id,
        category_id: categoryIds.get(category.toLowerCase()),
        subcategory_id: subcategoryId,
        name,
        description: DESCRIPTION,
        unit,
        srp,
        created_at: now,
      }),
    );
    console.log(`+ commodity ${name} [${category}, ${unit}, SRP ${srp}]`);
  }

  if (!writes.length) {
    console.log(`Nothing to add; all ${COMMODITIES.length} commodities already exist.`);
    return;
  }
  if (dryRun) {
    console.log(`Dry run: ${writes.length} documents would be written (${skipped} already exist).`);
    return;
  }
  const response = await fetch(`${databaseRoot}:commit`, {
    method: 'POST',
    headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'},
    body: JSON.stringify({writes}),
  });
  if (!response.ok) throw new Error(`Write failed: ${await response.text()}`);

  const added = (await listCollection('commodities', token)).filter((c) =>
    COMMODITIES.some(([, , name]) => name.toLowerCase() === String(c.name).toLowerCase()),
  );
  console.log(
    `Wrote ${writes.length} documents (${skipped} commodities already existed). ` +
      `Verified ${added.length}/${COMMODITIES.length} survey commodities in Firestore.`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
