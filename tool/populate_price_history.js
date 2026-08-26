const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const constants = fs.readFileSync(
  path.join(root, 'lib/core/constants/app_constants.dart'),
  'utf8',
);
const firebaseOptions = fs.readFileSync(
  path.join(root, 'lib/firebase_options.dart'),
  'utf8',
);

const readDartConstant = (name) => {
  const match = constants.match(
    new RegExp(`demo${name}\\s*=\\s*'([^']+)'`),
  );
  if (!match) throw new Error(`Could not read demo${name}.`);
  return match[1];
};

const apiKey = firebaseOptions.match(/apiKey:\s*'([^']+)'/)?.[1];
if (!apiKey) throw new Error('Could not read the Firebase API key.');

const projectId = 'pricewatch-apk';
const databaseRoot =
  `https://firestore.googleapis.com/v1/projects/${projectId}` +
  '/databases/(default)/documents';

const decodeValue = (value) => {
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  return value.stringValue ?? null;
};

const decodeDocument = (document) => ({
  documentId: document.name.split('/').pop(),
  ...Object.fromEntries(
    Object.entries(document.fields ?? {}).map(([key, value]) => [
      key,
      decodeValue(value),
    ]),
  ),
});

const encodeValue = (value) => {
  if (value === null) return {nullValue: null};
  if (typeof value === 'boolean') return {booleanValue: value};
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

const roundPrice = (value) => Math.round(value * 2) / 2;
const dateKey = (date) =>
  `${date.getUTCFullYear()}${String(date.getUTCMonth() + 1).padStart(2, '0')}` +
  String(date.getUTCDate()).padStart(2, '0');

const stableNumericId = (value) => {
  let hash = 1469598103934665603n;
  for (const character of value) {
    hash ^= BigInt(character.codePointAt(0));
    hash = BigInt.asUintN(64, hash * 1099511628211n);
  }
  return Number(6000000000000000n + (hash % 2000000000000000n));
};

async function main() {
  const authResponse = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: readDartConstant('AdminEmail'),
        password: readDartConstant('AdminPassword'),
        returnSecureToken: true,
      }),
    },
  );
  if (!authResponse.ok) {
    throw new Error(`Admin sign-in failed: ${await authResponse.text()}`);
  }
  const token = (await authResponse.json()).idToken;
  const [commodities, stores] = await Promise.all([
    listCollection('commodities', token),
    listCollection('stores', token),
  ]);
  const activeStores = stores
    .filter((store) => store.is_archived !== true)
    .sort((a, b) => Number(a.id) - Number(b.id));
  if (!commodities.length || !activeStores.length) {
    throw new Error('Commodities and active stores are required.');
  }

  const now = new Date();
  const dayOffsets = [330, 300, 270, 240, 210, 180, 150, 120, 90, 60, 45, 30, 14, 0];
  const writes = [];
  for (const commodity of commodities) {
    const commodityId = Number(commodity.id);
    const srp = Number(commodity.srp);
    if (!commodityId || !Number.isFinite(srp)) continue;
    const selectedStores = Array.from({length: Math.min(3, activeStores.length)}, (_, index) =>
      activeStores[(commodityId + index - 1) % activeStores.length],
    );
    for (const store of selectedStores) {
      const storeId = Number(store.id);
      for (let index = 0; index < dayOffsets.length; index++) {
        const recorded = new Date(now);
        recorded.setUTCHours(8, 0, 0, 0);
        recorded.setUTCDate(recorded.getUTCDate() - dayOffsets[index]);
        const key = dateKey(recorded);
        const wave = Math.sin((index + commodityId) * 0.82) * 0.055;
        const storeBias = ((storeId % 5) - 2) * 0.012;
        const gradualChange = (index / (dayOffsets.length - 1) - 0.5) * 0.045;
        const price = roundPrice(srp * (1 + wave + storeBias + gradualChange));
        const documentId = `history_v1_${commodityId}_${storeId}_${key}`;
        const id = stableNumericId(documentId);
        const fields = {
          id,
          commodity_id: commodityId,
          store_id: storeId,
          price,
          recorded_at: recorded.toISOString(),
          source: 'analytics-history-v1',
        };
        writes.push({
          update: {
            name: `projects/${projectId}/databases/(default)/documents/price_entries/${documentId}`,
            fields: Object.fromEntries(
              Object.entries(fields).map(([field, value]) => [field, encodeValue(value)]),
            ),
          },
        });
      }
    }
  }

  for (let index = 0; index < writes.length; index += 400) {
    const response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({writes: writes.slice(index, index + 400)}),
      },
    );
    if (!response.ok) {
      throw new Error(`History write failed: ${await response.text()}`);
    }
  }
  const verifiedRows = (await listCollection('price_entries', token)).filter(
    (entry) => entry.source === 'analytics-history-v1',
  );
  console.log(
    `Populated ${writes.length} idempotent price updates across ` +
      `${commodities.length} commodities and ${dayOffsets.length} dates. ` +
      `Verified ${verifiedRows.length} live history records.`,
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
