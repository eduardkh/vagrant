#!/usr/bin/env python3
"""Milestone 5: one protected pre-migration configuration snapshot."""
import os
from pathlib import Path
import tarfile

target = Path('/var/backups/jenkins-lab/pre-jcasc.tar.gz')
if not target.exists():
    with os.fdopen(os.open(str(target), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600), 'wb') as stream:
        with tarfile.open(fileobj=stream, mode='w:gz') as archive:
            home = Path('/var/lib/jenkins')
            for name in ('config.xml', 'users', 'credentials.xml', 'locale.xml',
                         'jenkins.model.JenkinsLocationConfiguration.xml', 'init.groovy.d'):
                if (home / name).exists():
                    archive.add(str(home / name), arcname='jenkins-home/' + name)
            archive.add('/etc/systemd/system/jenkins.service.d', arcname='service-dropins')
print('Protected pre-JCasC configuration snapshot is available')
