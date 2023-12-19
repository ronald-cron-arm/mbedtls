#!/usr/bin/env python3

import os
from pathlib import PurePath
import subprocess

tests_src_path = PurePath(os.path.expanduser('~/work/mbedtls/tests/src'))
print('mbedtls-2.28 as of:')
cmd = "git show mbedtls-2.28 --oneline"
subprocess.run(cmd.split())

print('development as of:')
cmd = "git show development --oneline"
subprocess.run(cmd.split())

for root, dirs, files in os.walk(tests_src_path):
    for file in files:
        file_path = PurePath(os.path.join(root, file))
        relative_file_path = file_path.relative_to(tests_src_path)
        print(relative_file_path)
        print('=' * len(str(relative_file_path)) + '\n')

        cmd = "git log mbedtls-2.28.0..mbedtls-2.28.5 --oneline -- " + str(file_path)
        print(cmd)
        subprocess.run(cmd.split())
        print()

        cmd = "git diff mbedtls-2.28 development -- " + str(file_path)
        print(cmd)
        subprocess.run(cmd.split())
        print()

for root, dirs, files in os.walk(tests_src_path):
    for file in files:
        file_path = PurePath(os.path.join(root, file))
        cmd = "git log mbedtls-2.28.0..mbedtls-2.28.5 --oneline -- " + str(file_path)
        subprocess.run(cmd.split())
