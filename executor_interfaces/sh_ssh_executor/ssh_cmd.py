#!/usr/bin/env python

import sys
import time
import paramiko

hostname = sys.argv[1]
port = sys.argv[2]
username = sys.argv[3]
password = sys.argv[4]
key_path = sys.argv[5]
command = sys.argv[6]

ssh = None
pkey = None

try:
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    if(len(password) > 0):
        ssh.connect(hostname, port=port, username=username, password=password)
    elif(len(key_path) > 0):
        pkey = paramiko.RSAKey.from_private_key_file(key_path)
        ssh.connect(hostname, port=port, username=username, pkey=pkey)
    else:
        print("No password or keypath given", file=sys.stderr)
        sys.exit(1)

    stdin, stdout, stderr = ssh.exec_command(command)
    for l in stdout.readlines():
        print(l, file=sys.stdout, end='')
    for l in stderr.readlines():
        print(l, file=sys.stderr, end='')

except AuthenticationException as AuthException:
    print("Authentication failed: %s" % AuthException, file=sys.stderr)
    sys.exit(1)
except SSHException as sshException:
    print("Unable to connect: %s" % sshException, file=sys.stderr)
    sys.exit(1)
except BadHostKeyException as badHostKeyException:
    print("Unable to verify server's host key: %s" %
          badHostKeyException, file=sys.stderr)
    sys.exit(1)
except:
    e = sys.exc_info()[0]
    print("Unable to execute command: %s" % e, file=sys.stderr)
    sys.exit(1)

finally:
    time.sleep(.2)
    if(ssh is not None):
        ssh.close()
    sys.exit(0)
