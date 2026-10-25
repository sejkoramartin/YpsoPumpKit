"""Synthetic fixtures only. No pump captures, real keys or command encoding.
Independent Python caller for libsodium; not an independent cipher implementation.
"""
import ctypes,ctypes.util,json,struct
from pathlib import Path
s=ctypes.CDLL(ctypes.util.find_library('sodium'))
assert s.sodium_init()>=0
f=s.crypto_aead_xchacha20poly1305_ietf_encrypt
f.argtypes=[ctypes.c_void_p,ctypes.POINTER(ctypes.c_ulonglong),ctypes.c_void_p,ctypes.c_ulonglong,ctypes.c_void_p,ctypes.c_ulonglong,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p]
f.restype=ctypes.c_int
key=bytes(range(32))
body=bytes([3])+struct.pack('<I',12345)+bytes([4])+struct.pack('<III',0,100,0)
crc=0xffffffff
for base in range(0,len(body),4):
 for b in body[base:base+4].ljust(4,b'\0')[::-1]:
  crc^=b<<24
  for _ in range(8):crc=((crc<<1)^(0x04c11db7 if crc&0x80000000 else 0))&0xffffffff
body+=struct.pack('<H',crc&0xffff)
vectors=[]
for i,(name,reboot,counter,payload) in enumerate([
 ('first',7,1,body),('second',7,2,body),('bad_crc',7,3,body[:-1]+bytes([body[-1]^1])),
 ('restart',8,4,body),('old_reboot',6,4,body),('empty_body',7,4,b'')]):
 nonce=bytes([i])+bytes(range(1,24))
 plain=payload+struct.pack('<IQ',reboot,counter)
 out=ctypes.create_string_buffer(len(plain)+16);length=ctypes.c_ulonglong()
 assert f(out,ctypes.byref(length),plain,len(plain),None,0,None,nonce,key)==0
 vectors.append(dict(name=name,envelope=(out.raw[:length.value]+nonce).hex(),body=payload.hex(),reboot=reboot,counter=counter))
Path(__file__).parent.joinpath('OfflineCryptoTests/Fixtures/responses.json').write_text(json.dumps(dict(key=key.hex(),vectors=vectors),indent=2)+'\n')
