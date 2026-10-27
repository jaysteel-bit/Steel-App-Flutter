// Public test fixture only. Node uses its OpenSSL-backed Ed25519 verifier.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const fixture = JSON.parse(fs.readFileSync(__dirname + '/protocol-fixture.json'));
function canonical(v) {
  if (Array.isArray(v)) return '[' + v.map(canonical).join(',') + ']';
  if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map(k => JSON.stringify(k)+':'+canonical(v[k])).join(',') + '}';
  return JSON.stringify(v);
}
function verify(envelope, rawKey) {
  const key = crypto.createPublicKey({format:'der', type:'spki', key:Buffer.concat([
    Buffer.from('302a300506032b6570032100','hex'), Buffer.from(rawKey,'base64url')])});
  return crypto.verify(null, Buffer.from('steel-envelope-v1\n'+canonical(envelope.payload)), key, Buffer.from(envelope.signature,'base64url'));
}
assert.equal('steel-envelope-v1\n'+canonical(fixture.proof.payload), fixture.proofCanonicalSigningText);
assert(verify(fixture.proof,fixture.rootPublicKey));
assert(verify(fixture.grant,fixture.rootPublicKey));
assert(verify(fixture.request,fixture.grant.payload.delegateKey));
assert(!verify(fixture.request,fixture.rootPublicKey));
fixture.proof.payload.profile.name = 'tampered';
assert(!verify(fixture.proof,fixture.rootPublicKey));
console.log('Dart → Node interoperability: 3 valid signatures, wrong key and tampering rejected.');
