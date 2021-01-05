# SSH Executor interface

Execute applications on a remote machine via SSH connection. This can be accomplished specifying username and passwword or username and private key file path.
The executor interface requires the following infrastructure parameter values:

| Parameter        | Description                                           |
| ---------------- | ----------------------------------------------------- |
| `infra_host`     | Host address of the remote machine                    |
| `infra_port`     | SSH port number of the remote machine                 |
| `infra_user`     | SSH username                                          |
| `infra_password` | SSH password (alternatively to private key file path) |
| `infra_sshkey`   | SSH private key file path (alternatively to password) |

Application parameter using this executor interface must have

| Parameter | Description                             |
| --------- | --------------------------------------- |
| `jobdesc` | Filename containing the job description |

Below a job description file content example:

```bash
executable=/bin/bash
arguments=test.sh arg1 arg2 arg3
stdout=output.txt
stderr=error.txt
output_files=test_output.tx
```

The `stdout` and `stderr` parameters are not mandatory, in such a case hidden files will be used.

## Configuration

This executor interface requires python 3 and paramiko package in the virtual environment;
below the instructions to setup the environment:

```bash
# Instructions assume the current directory in: shAPIServer/
cd executor_interfaces/sh_ssh_executor
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
deactivate
```

## Test

The test assumes the remote host running under futuregateway/sshnode container running in the same machine hosting the shAPIServer daemon. The container has to map 22th port to 8022 and it also need a new user named fgtest_key with configured the passwordless access using the private and public key files in ~/.ssh directory.

### ssh_cmd

Execute an `ls -l /` command on the given remote host

```bash
# Using username/password
./ssh_cmd.py localhost 8022 fgtest fgtest "" "ls -l /" &&\
echo "Test using password successful" ||\
echo "Test using password failed"
# Using pkey file
./ssh_cmd.py localhost 8022 fgtest_key ""  ~/.ssh/id_rsa "ls -l /" &&\
echo "Test using key successful" ||\
echo "Test using key failed"
```

### scp_cmd

Execute a series of file copy operations from/to the given remote host

```bash
touch test &&\
./scp_cmd.py localhost 8022 fgtest fgtest "" test ">" test_upload &&\
./ssh_cmd.py localhost 8022 fgtest fgtest "" "ls -l test_upload" &&\
./scp_cmd.py localhost 8022 fgtest fgtest "" test_download "<" test_upload &&\
ls -l test_download &&\
rm -f test test_download &&\
./ssh_cmd.py localhost 8022 fgtest fgtest "" "rm -f test_upload" &&\
echo "Test using password successful" ||\
echo "Test using password failed"

touch testwithkey &&\
./scp_cmd.py localhost 8022 fgtest_key "" ~/.ssh/id_rsa testwithkey ">" testwithkey_upload &&\
./ssh_cmd.py localhost 8022 fgtest_key "" ~/.ssh/id_rsa "ls -l testwithkey_upload" &&\
./scp_cmd.py localhost 8022 fgtest_key "" ~/.ssh/id_rsa testwithkey_download "<" testwithkey_upload &&\
ls -l testwithkey_download &&\
rm -f testwithkey testwithkey_download &&\
./ssh_cmd.py localhost 8022 fgtest_key "" ~/.ssh/id_rsa "rm -f testwithkey_upload" &&\
echo "Test using key successful" ||\
echo "Test using key failed"
```
