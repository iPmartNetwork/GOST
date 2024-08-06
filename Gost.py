# range [min, max]

def checkNumRange(userin, min, max):
    # option must be int
    if userin.isdigit():
        if int(userin) >= min and int(userin) <= max:
            return int(userin)
    
    return -1

Ltype = -1
while Ltype == -1:
    print('Choose Listening type:\n1. TCP\n2. UDP\n3. TCP and UDP')

    Ltype = checkNumRange(input("Please have a choice:"), 1, 3)

Lport = -1
while Lport == -1:
    Lport = checkNumRange(input("Choose Listening port[0-65535]:"), 0, 65535)

TranP = -1
while TranP == -1:
    print('Choose Transport protocol:\n1. relay\n2. forward')
    TranP = checkNumRange(input("Please have a choice:"), 1, 2)
options = ['relay', 'forward']
TranP = options[TranP-1]

TranM = -1
wsPath = ""
while TranM == -1:
    print('Choose Transport method:\n1. ws\n2.wss\n3.mws\n4.mwss\n5.tls\n6.mtls')
    TranM = checkNumRange(input("Please have a choice:"), 1, 6)
    
if TranM <= 4:
    wsPath = "&path=/" + input("Please input ws path[default '/']\nDon't add '/' just name:")

options = ['ws', 'wss', 'mws', 'mwss', 'tls', 'mtls']
TranM = options[TranM-1]

TarIPAddr = -1
while TarIPAddr == -1:
    TarIPAddr = input("Please input target ip address or domain: ")

TarIPort = -1
while TarIPort == -1:
    TarIPort = checkNumRange(input("Please input target port[0-65535]: "), 0, 65535)

ISmbind = -1
while ISmbind == -1:
    print("Please choose mbind True or False:\n1.True\n2.False")
    ISmbind = checkNumRange(input("Please have a choice:"), 1, 2)
options = ['True', 'False']
ISmbind = options[ISmbind-1]

TarVPNPort = -1
while TarVPNPort == -1:
    TarVPNPort = checkNumRange(input("Please input target VPN server(ssr, v2ray, etc.) port[0-65535]: "), 0, 65535)

if Ltype == 1:
    print("./gost -L=tcp://:%d -F=%s+%s://%s:%d?mbind=%s%s" % (Lport, TranP, TranM, TarIPAddr, TarIPort, ISmbind, wsPath))
    print("./gost -L=%s://:%d/127.0.0.1:%d?%s" % (TranM, TarIPort, TarVPNPort, wsPath))
elif Ltype == 2:
    print("./gost -L=udp://:%d -F=%s+%s://%s:%d?mbind=%s%s" % (Lport, TranP, TranM, TarIPAddr, TarIPort, ISmbind, wsPath))
    print("./gost -L=%s://:%d/127.0.0.1:%d?%s" % (TranM, TarIPort, TarVPNPort, wsPath))
elif Ltype == 3:
    print("./gost -L=tcp://:%d -L=udp://:%d -F=%s+%s://%s:%d?mbind=%s%s" % (Lport, Lport, TranP, TranM, TarIPAddr, TarIPort, ISmbind, wsPath))
    print("./gost -L=%s://:%d/127.0.0.1:%d?%s" % (TranM, TarIPort, TarVPNPort, wsPath))
    
