# Bare Executor interface

Execute applications on a remote machine via SSH connection. This can be accomplished specifying username and passwword or username and private key file path.
The executor interface requires the following infrastructure parameter values:

| Parameter | Description                                                                                     |
| --------- | ----------------------------------------------------------------------------------------------- |
| `user`    | Username responsible for the execution (not mandatory), using shAPIServer user if not specified |

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

This executor interface does not require any configuration
