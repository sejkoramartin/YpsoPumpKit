"""Cross-check synthetic libsodium fixtures with PyCryptodome; no real keys or I/O."""
import json
import struct
from pathlib import Path

try:
    from Cryptodome.Cipher import ChaCha20_Poly1305
except ImportError:
    from Crypto.Cipher import ChaCha20_Poly1305

fixtures = json.loads((Path(__file__).parent / 'OfflineCryptoTests/Fixtures/responses.json').read_text())
key = bytes.fromhex(fixtures['key'])
for vector in fixtures['vectors']:
    envelope = bytes.fromhex(vector['envelope'])
    ciphertext, tag, nonce = envelope[:-40], envelope[-40:-24], envelope[-24:]
    plaintext = ChaCha20_Poly1305.new(key=key, nonce=nonce).decrypt_and_verify(ciphertext, tag)
    expected = bytes.fromhex(vector['body']) + struct.pack('<IQ', vector['reboot'], vector['counter'])
    if plaintext != expected:
        raise AssertionError(vector['name'])
    altered = bytes([ciphertext[0] ^ 1]) + ciphertext[1:]
    try:
        ChaCha20_Poly1305.new(key=key, nonce=nonce).decrypt_and_verify(altered, tag)
    except ValueError:
        pass
    else:
        raise AssertionError('Mutation accepted: ' + vector['name'])
print(f"Verified {len(fixtures['vectors'])} synthetic vectors with independent PyCryptodome implementation")
