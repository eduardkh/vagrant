#!/usr/bin/env python3
"""Milestone 5: limited validation diagnostics, with managed secrets redacted."""
from pathlib import Path
import re
import subprocess

result = subprocess.run(['journalctl', '-u', 'jenkins-jcasc-check-*', '-n', '300',
                         '--no-pager', '-o', 'cat'], capture_output=True, text=True)
lines = [line for line in result.stdout.splitlines()
         if any(word in line for word in ('Exception', 'Error', 'SEVERE', 'WARNING', 'Failed'))]
text = '\n'.join(lines)
for path in Path('/etc/jenkins-lab/secrets').iterdir():
    if path.is_file():
        value = path.read_text()
        if value:
            text = text.replace(value, '<redacted>')
text = re.sub(r'#jbcrypt:\S+', '<redacted-hash>', text)
print(text[-7000:] or 'No startup exceptions found in the validation journal')
