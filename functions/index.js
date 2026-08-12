const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const crypto = require('crypto');

initializeApp();
const db = getFirestore();
const auth = getAuth();
const pepper = 'pricewatch-local-app';

function constantTimeEqual(left, right) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function verifyLegacyPassword(password, email, stored) {
  if (!stored || typeof stored !== 'string') return false;
  if (stored.startsWith('v2$')) {
    const parts = stored.split('$');
    if (parts.length !== 3) return false;
    const salt = parts[1];
    const seed = Buffer.from(`${email.toLowerCase()}|${password}|${salt}|${pepper}`);
    let digest = crypto.createHash('sha256').update(seed).digest();
    for (let round = 1; round < 20000; round++) {
      digest = crypto.createHash('sha256').update(Buffer.concat([digest, seed])).digest();
    }
    return constantTimeEqual(digest.toString('base64url') + '=', parts[2]);
  }
  const legacy = crypto
    .createHash('sha256')
    .update(`${email.toLowerCase()}|${password}|${pepper}`)
    .digest('hex');
  return constantTimeEqual(legacy, stored);
}

async function requireAdmin(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  const access = await db.collection('access_control').doc(request.auth.uid).get();
  if (!access.exists || access.data().role !== 'admin' || access.data().active === false) {
    throw new HttpsError('permission-denied', 'Administrator access required.');
  }
  return access.data();
}

exports.migrateLegacyUser = onCall(async (request) => {
  try {
    const email = String(request.data?.email || '').trim().toLowerCase();
    const password = String(request.data?.password || '');
    if (!email || !password) throw new HttpsError('invalid-argument', 'Email and password are required.');

    const matches = await db.collection('users').where('email', '==', email).limit(1).get();
    if (matches.empty) throw new HttpsError('not-found', 'Incorrect email or password.');
    const profile = matches.docs[0];
    const data = profile.data();
    if (!verifyLegacyPassword(password, email, data.password_hash)) {
      throw new HttpsError('permission-denied', 'Incorrect email or password.');
    }

    let authUser;
    try {
      authUser = await auth.getUserByEmail(email);
      await auth.updateUser(authUser.uid, {password, displayName: data.full_name});
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      authUser = await auth.createUser({email, password, displayName: data.full_name});
    }
    const userId = Number(data.id);
    const batch = db.batch();
    batch.update(profile.ref, {auth_uid: authUser.uid, password_hash: FieldValue.delete()});
    batch.set(db.collection('access_control').doc(authUser.uid), {
      uid: authUser.uid,
      user_id: userId,
      role: data.role || 'user',
      store_id: data.store_id || null,
      active: true,
      migrated_at: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    return {migrated: true};
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('Legacy migration failed', error);
    throw new HttpsError(
      'internal',
      'The server could not migrate this legacy account.',
    );
  }
});

exports.saveManagedUser = onCall(async (request) => {
  await requireAdmin(request);
  const input = request.data || {};
  const email = String(input.email || '').trim().toLowerCase();
  const fullName = String(input.fullName || '').trim();
  const role = String(input.role || 'vendor');
  const password = String(input.password || '');
  if (!email || !fullName || !['vendor', 'admin', 'user'].includes(role)) {
    throw new HttpsError('invalid-argument', 'Valid name, email, and role are required.');
  }
  if (!input.authUid && password.length < 6) {
    throw new HttpsError('invalid-argument', 'A password with at least six characters is required.');
  }

  let authUser;
  if (input.authUid) {
    const changes = {email, displayName: fullName};
    if (password) changes.password = password;
    authUser = await auth.updateUser(String(input.authUid), changes);
  } else {
    authUser = await auth.createUser({email, password, displayName: fullName});
  }
  const userId = Number(input.userId || Date.now() * 1000 + Math.floor(Math.random() * 1000));
  const storeId = input.storeId == null ? null : Number(input.storeId);
  const userRef = db.collection('users').doc(String(userId));
  const existing = await userRef.get();
  const batch = db.batch();
  batch.set(userRef, {
    id: userId,
    auth_uid: authUser.uid,
    full_name: fullName,
    email,
    role,
    store_id: role === 'vendor' ? storeId : null,
    created_at: existing.data()?.created_at || new Date().toISOString(),
  });
  batch.set(db.collection('access_control').doc(authUser.uid), {
    uid: authUser.uid,
    user_id: userId,
    role,
    store_id: role === 'vendor' ? storeId : null,
    active: true,
    updated_at: FieldValue.serverTimestamp(),
  }, {merge: true});
  await batch.commit();
  return {userId, authUid: authUser.uid};
});

exports.deleteManagedUser = onCall(async (request) => {
  await requireAdmin(request);
  const userId = Number(request.data?.userId);
  const profile = await db.collection('users').doc(String(userId)).get();
  if (!profile.exists) throw new HttpsError('not-found', 'User not found.');
  const data = profile.data();
  if (data.role === 'admin') throw new HttpsError('failed-precondition', 'Admin accounts cannot be deleted here.');
  if (data.auth_uid) await auth.deleteUser(data.auth_uid);
  const batch = db.batch();
  batch.delete(profile.ref);
  if (data.auth_uid) batch.delete(db.collection('access_control').doc(data.auth_uid));
  await batch.commit();
  return {deleted: true};
});
