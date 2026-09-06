"""Keep existing daemon options while assigning distinct gRPC ports."""
import re
from pathlib import Path

path = Path('/etc/frr/daemons')
text = path.read_text()
for daemon, port in [('zebra', 50051), ('bgpd', 50052),
                     ('ospfd', 50053), ('staticd', 50054)]:
    pattern = rf'^{daemon}_options="(.*)"$'
    match = re.search(pattern, text, re.MULTILINE)
    options = match.group(1) if match else ' -A 127.0.0.1'
    options = re.sub(r'\s+-M\s+grpc(?::\d+)?(?=\s|$)', '', options)
    line = f'{daemon}_options="{options} -M grpc:{port}"'
    if match:
        text = text[:match.start()] + line + text[match.end():]
    else:
        text += '\n' + line + '\n'
path.write_text(text)
