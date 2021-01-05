#!/usr/bin/env python

import sys
import time
import paramiko

hostname = sys.argv[1]
port = sys.argv[2]
username = sys.argv[3]
password = sys.argv[4]
key_path = sys.argv[5]
local_path = sys.argv[6]
path_way = sys.argv[7]
remote_path = sys.argv[8]

ssh = None
sftp = None
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

    sftp = ssh.open_sftp()
    if(path_way == ">"):
        sftp.put(local_path, remote_path)
    elif(path_way == "<"):
        sftp.get(remote_path, local_path)
    else:
        print("No path way given", file=sys.stderr)
        sys.exit(1)

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
    if(sftp is not None):
        sftp.close()
    if(ssh is not None):
        ssh.close()
    sys.exit(0)
