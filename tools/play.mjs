#!/usr/bin/env node
// Google Play Developer API — pa asnjë varësi.
//
//   node play.mjs <sherbimi.json> kontrollo <paketa>
//   node play.mjs <sherbimi.json> ngarko    <paketa> <skedari.aab> [gjurma]
//
// `kontrollo` është hapi i parë dhe i vetmi që duhet të besohet: ai thotë nëse
// llogaria e shërbimit e sheh vërtet aplikacionin. Tri gjëra ndryshme dështojnë
// këtu dhe ngatërrohen lehtë me njëra-tjetrën:
//   401  → çelësi/koha e sistemit
//   403  → llogaria s'është ftuar te Play Console, ose s'ka të drejtën «Lëshimet»
//   404  → paketa nuk ekziston ende te Play Console
// Vetëm e treta zgjidhet duke krijuar aplikacionin me dorë; API-ja NUK di ta
// krijojë një aplikacion të ri, dhe ngarkimin e parë e pranon vetëm pasi paketa
// të ekzistojë.
//
// Gjurmët: internal | alpha (testim i mbyllur) | beta (i hapur) | production

import { readFileSync } from 'node:fs';
import { createSign } from 'node:crypto';

const [, , keyPath, cmd, pkg, aabPath, track = 'internal'] = process.argv;
if (!keyPath || !cmd || !pkg) {
  console.error('përdorimi: play.mjs <sherbimi.json> kontrollo|ngarko <paketa> [aab] [gjurma]');
  process.exit(2);
}

const key = JSON.parse(readFileSync(keyPath, 'utf8'));
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const UPLOAD = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';

const b64u = b => Buffer.from(b).toString('base64url');

async function token() {
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const body = `${b64u(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64u(JSON.stringify(claim))}`;
  const sig = createSign('RSA-SHA256').update(body).end().sign(key.private_key).toString('base64url');

  const r = await fetch(claim.aud, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${body}.${sig}`,
    }),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`token ${r.status}: ${JSON.stringify(j)}`);
  return j.access_token;
}

const TOK = await token();

async function call(url, { method = 'GET', json, raw, type } = {}) {
  const r = await fetch(url, {
    method,
    headers: {
      authorization: `Bearer ${TOK}`,
      ...(json ? { 'content-type': 'application/json' } : {}),
      ...(type ? { 'content-type': type } : {}),
    },
    body: json ? JSON.stringify(json) : raw,
  });
  const text = await r.text();
  if (!r.ok) throw new Error(`${method} ${url.replace(/\?.*/, '')} → ${r.status}\n${text}`);
  return text ? JSON.parse(text) : {};
}

if (cmd === 'kontrollo') {
  const edit = await call(`${API}/applications/${pkg}/edits`, { method: 'POST', json: {} });
  const tracks = await call(`${API}/applications/${pkg}/edits/${edit.id}/tracks`);
  console.log(`✓ hyrja funksionon për ${pkg}`);
  for (const t of tracks.tracks ?? []) {
    const rel = (t.releases ?? [])
      .map(r => `${r.status} ${(r.versionCodes ?? []).join(',') || '—'}`)
      .join(' | ') || 'bosh';
    console.log(`  ${t.track.padEnd(12)} ${rel}`);
  }
  await call(`${API}/applications/${pkg}/edits/${edit.id}`, { method: 'DELETE' });

} else if (cmd === 'ngarko') {
  if (!aabPath) throw new Error('mungon skedari .aab');
  const bytes = readFileSync(aabPath);

  const edit = await call(`${API}/applications/${pkg}/edits`, { method: 'POST', json: {} });
  console.log(`… ndryshimi ${edit.id}`);

  const bundle = await call(
    `${UPLOAD}/applications/${pkg}/edits/${edit.id}/bundles?uploadType=media`,
    { method: 'POST', raw: bytes, type: 'application/octet-stream' },
  );
  console.log(`… u ngarkua versionCode ${bundle.versionCode}`);

  await call(`${API}/applications/${pkg}/edits/${edit.id}/tracks/${track}`, {
    method: 'PUT',
    json: { track, releases: [{ status: 'completed', versionCodes: [String(bundle.versionCode)] }] },
  });
  console.log(`… u vendos te gjurma «${track}»`);

  await call(`${API}/applications/${pkg}/edits/${edit.id}:commit`, { method: 'POST' });
  console.log(`✓ u krye: ${pkg} ${bundle.versionCode} → ${track}`);

} else {
  console.error(`urdhër i panjohur: ${cmd}`);
  process.exit(2);
}
