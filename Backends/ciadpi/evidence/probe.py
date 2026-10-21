import socket,subprocess,os,threading,time,json,sys
root=os.getcwd()
echo=socket.socket();echo.bind(('127.0.0.1',0));echo.listen();ep=echo.getsockname()[1]
def eserver():
 while True:
  try:c,_=echo.accept()
  except OSError:break
  def client(c):
   with c:
    while True:
     b=c.recv(10000)
     if not b:break
     c.sendall(b)
  threading.Thread(target=client,args=(c,),daemon=True).start()
threading.Thread(target=eserver,daemon=True).start()
s=socket.socket();s.bind(('127.0.0.1',0));p=s.getsockname()[1];s.close()
proc=subprocess.Popen([sys.argv[1],'-i','127.0.0.1','-p',str(p),'-X'],env=dict(os.environ,DYLD_INSERT_LIBRARIES=root+'/delay.dylib'),stderr=subprocess.PIPE,stdout=subprocess.DEVNULL)
try:
 for _ in range(100):
  try:s=socket.create_connection(('127.0.0.1',p),.1);s.close();break
  except OSError:time.sleep(.02)
 def greet():
  c=socket.create_connection(('127.0.0.1',p),4);c.settimeout(5);c.sendall(b'\x05\x01\x00');assert c.recv(2)==b'\x05\x00';return c
 def conn(host=None):
  c=greet();c.sendall(b'\x05\x01\x00'+(b'\x01\x7f\x00\x00\x01' if host is None else b'\x03'+bytes([len(host)])+host)+ep.to_bytes(2,'big'));return c
 tunnel=conn();assert tunnel.recv(10)[1]==0
 slow=conn(b'slow.test')
 while b'DNS_SENTINEL' not in proc.stderr.readline():pass
 result={}
 def greeting():
  t=time.monotonic();c=greet();result['greeting_ms']=round((time.monotonic()-t)*1000,1);c.close()
 th=threading.Thread(target=greeting);th.start();t=time.monotonic();tunnel.sendall(b'alive');assert tunnel.recv(5)==b'alive';result['tunnel_ms']=round((time.monotonic()-t)*1000,1);th.join();assert slow.recv(10)[1]==0
 fail=conn(b'fail.test');result['dns_failure_reply']=fail.recv(10).hex();fail.close()
 if '--extended' in sys.argv:
  # Saturation, cancellation, late completion, then reuse of resolver capacity.
  stalled=[conn(b'slow.test') for _ in range(8)]
  time.sleep(.1)
  ninth=conn(b'slow.test');result['saturation_reply']=ninth.recv(10).hex();ninth.close()
  t=time.monotonic();fresh=greet();fresh.close();result['saturated_greeting_ms']=round((time.monotonic()-t)*1000,1)
  for c in stalled:c.close()
  time.sleep(3.2)
  reused=conn(b'slow.test');assert reused.recv(10)[1]==0;reused.close()
  result['cancel_late_completion_reuse']='passed'
  # SOCKS4a DNS keeps its original success response.
  s4=socket.create_connection(('127.0.0.1',p),4);s4.settimeout(5)
  s4.sendall(b'\x04\x01'+ep.to_bytes(2,'big')+b'\x00\x00\x00\x01\x00slow.test\x00')
  assert s4.recv(8)[1]==90;s4.sendall(b's4');assert s4.recv(2)==b's4';s4.close();result['socks4a']='passed'
  # UDP-domain replay must retain the pre-existing three-event association.
  ue=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);ue.bind(('127.0.0.1',0));up=ue.getsockname()[1]
  def udp_echo():
   for _ in range(2):
    b,a=ue.recvfrom(65535);ue.sendto(b,a)
  threading.Thread(target=udp_echo,daemon=True).start()
  control=greet();control.sendall(b'\x05\x03\x00\x01\x00\x00\x00\x00\x00\x00');reply=control.recv(10);assert reply[1]==0
  relay=('127.0.0.1',int.from_bytes(reply[-2:],'big'));u=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);u.settimeout(5)
  packet=b'\x00\x00\x00\x03\x09slow.test'+up.to_bytes(2,'big')
  u.sendto(packet+b'udp-one',relay);time.sleep(.1)
  t=time.monotonic();fresh=greet();fresh.close();result['udp_dns_greeting_ms']=round((time.monotonic()-t)*1000,1)
  assert u.recv(100).endswith(b'udp-one')
  u.sendto(packet+b'udp-two',relay);assert u.recv(100).endswith(b'udp-two')
  result['udp_domain_twice']='passed';u.close();control.close();ue.close()
 print(json.dumps(result),flush=True);tunnel.close();slow.close()
finally:
 proc.kill();proc.wait(timeout=4);echo.close()
