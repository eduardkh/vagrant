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
digest = hashlib.sha256(candidate.read_bytes() + settings_path.read_bytes() + hook.read_bytes() + lock.read_bytes()).hexdigest()
home = Path('/var/lib/jenkins-jcasc-validation') / digest
marker = home.parent / (digest + '.validated')
if marker.exists():
    print(json.dumps({'changed': False, 'validated': True}))
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
            request = urllib.request.Request('http://127.0.0.1:%s/login' % port,
                                             headers={'Accept-Language': 'he-IL,he;q=0.9'})
            try:
                response = urllib.request.urlopen(request, timeout=5)
            except urllib.error.HTTPError as error:
                response = error
            except urllib.error.URLError:
                time.sleep(2)
                continue
            with response:
                if response.headers.get('X-Jenkins-Language') == 'en' and response.status == 200:
                    marker.write_text('Validated isolated JCasC startup\n')
                    print(json.dumps({'changed': True, 'validated': True}))
                    break
        if attempt > 5 and subprocess.run(['systemctl', 'is-active', '--quiet', unit]).returncode != 0:
            raise RuntimeError('Isolated Jenkins failed startup; inspect protected validation home/journal for unit ' + unit)
        time.sleep(2)
    else:
        raise RuntimeError('Isolated JCasC validation timed out for unit ' + unit)
finally:
    subprocess.run(['systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
