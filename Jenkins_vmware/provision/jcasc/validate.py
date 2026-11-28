#!/usr/bin/env python3
"""Milestone 5: validate YAML in an isolated Jenkins home before live promotion.

The temporary service listens on loopback only and is stopped in finally.
No existing Jenkins data is copied, and no password/token is printed.
"""
import hashlib
import json
import os
from pathlib import Path
import pwd
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

from verify import verify

candidate = Path(sys.argv[1])
settings_path = Path(sys.argv[2])
settings = json.loads(settings_path.read_text())
hook = Path('/etc/jenkins-lab/jcasc/runtime-check.groovy')
lock = Path('/etc/jenkins-lab/plugins/plugins.lock.json')
inputs = candidate.read_bytes() + settings_path.read_bytes() + hook.read_bytes() + lock.read_bytes() + Path(__file__).read_bytes()
for folder in ('/etc/jenkins-lab/secrets', '/etc/jenkins-lab/trust', '/etc/jenkins-lab/agent-linux'):
    directory = Path(folder)
    if directory.exists():
        for item in sorted(directory.iterdir()):
            if item.is_file():
                inputs += item.name.encode() + item.read_bytes()
smoke_hook = Path('/var/lib/jenkins/init.groovy.d/98-linux-smoke.groovy')
if smoke_hook.exists():
    inputs += smoke_hook.read_bytes()
digest = hashlib.sha256(inputs).hexdigest()
home = Path('/var/lib/jenkins-jcasc-validation') / digest
marker = home.parent / (digest + '.validated')
if marker.exists():
    print(json.dumps({'changed': False, 'validated': True, 'fingerprint': digest}))
    sys.exit(0)
account = pwd.getpwnam('jenkins')
for directory in (home, home / 'plugins', home / 'init.groovy.d'):
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chown(str(directory), account.pw_uid, account.pw_gid)
for plugin in json.loads(lock.read_text()):
    link = home / 'plugins' / (plugin['id'] + '.jpi')
    if not link.exists():
        link.symlink_to(Path('/var/lib/jenkins/plugins') / (plugin['id'] + '.jpi'))
probe_hook = home / 'init.groovy.d' / '95-jcasc-validation.groovy'
probe_hook.write_bytes(hook.read_bytes())
os.chown(str(probe_hook), account.pw_uid, account.pw_gid)
with socket.socket() as listener:
    listener.bind(('127.0.0.1', 0))
    port = listener.getsockname()[1]
unit = 'jenkins-jcasc-check-' + digest[:12]
command = [
    'systemd-run', '--quiet', '--collect', '--unit=' + unit,
    '--property=User=jenkins', '--property=Group=jenkins', '--property=UMask=0077',
    # The probe must never launch a second connection to the real build worker.
    '--property=PrivateNetwork=yes',
    '--setenv=JENKINS_HOME=' + str(home),
    '--setenv=CASC_JENKINS_CONFIG=' + str(candidate),
    settings['java_home'] + '/bin/java', '-Xmx768m', '-Djava.awt.headless=true',
    '-Djenkins.install.runSetupWizard=false', '-jar', '/usr/share/java/jenkins.war',
    '--httpPort=' + str(port), '--httpListenAddress=127.0.0.1', '--webroot=' + str(home / 'war'),
]
try:
    started_at = int(time.time())
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
    for attempt in range(120):
        journal = subprocess.run(['journalctl', '-u', unit, '--since=@' + str(started_at),
                                  '--no-pager', '-o', 'cat'], capture_output=True, text=True).stdout
        if 'Failed ConfigurationAsCode.init' in journal or 'Failed to initialize Jenkins' in journal:
            raise RuntimeError('Candidate JCasC startup failed; live configuration was not promoted. Validation unit: ' + unit)
        if (home / 'milestone-5-jcasc.json').exists():
            verify(home, settings, str(candidate))
            pid = subprocess.check_output(['systemctl', 'show', unit, '-p', 'MainPID', '--value'], text=True).strip()
            # Enter only the probe's network namespace to inspect loopback HTTP.
            probe_code = ('import json,sys,urllib.request; '
                          'r=urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:"+sys.argv[1]+"/login",'
                          'headers={"Accept-Language":"he-IL,he;q=0.9"}),timeout=5); '
                          'print(json.dumps({"status":r.status,"language":r.headers.get("X-Jenkins-Language")}))')
            probe = subprocess.run(['nsenter', '--target', pid, '--net', '/usr/bin/python3.9', '-c', probe_code, str(port)],
                                   capture_output=True, text=True, timeout=10)
            if probe.returncode == 0:
                response = json.loads(probe.stdout)
                if response['language'] == 'en' and response['status'] == 200:
                    marker.write_text('Validated isolated JCasC startup\n')
                    print(json.dumps({'changed': True, 'validated': True, 'fingerprint': digest}))
                    break
        if attempt > 5 and subprocess.run(['systemctl', 'is-active', '--quiet', unit]).returncode != 0:
            raise RuntimeError('Isolated Jenkins failed startup; inspect protected validation home/journal for unit ' + unit)
        time.sleep(2)
    else:
        raise RuntimeError('Isolated JCasC validation timed out for unit ' + unit)
finally:
    subprocess.run(['systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
