#!/usr/bin/env python3
"""Milestone 5: verify public runtime facts and password preservation quietly."""
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def verify(home, settings, source):
    home = Path(home)
    report = json.loads((home / 'milestone-5-jcasc.json').read_text())
    expected = {
        'executors': 0, 'mode': 'EXCLUSIVE', 'signup': False,
        'realm': 'hudson.security.HudsonPrivateSecurityRealm',
        'authorization': 'hudson.security.GlobalMatrixAuthorizationStrategy',
        'anonymousRead': False, 'adminExists': True, 'adminCanAdminister': True, 'credentialPresent': True,
        'url': settings['url'], 'language': 'en', 'ignoreBrowser': True,
        'allowUserPreferences': False,
    }
    mismatches = [key for key, value in expected.items() if report.get(key) != value]
    if settings.get('linux_agent'):
        agent = settings['linux_agent']
        expected_agent = {
            'name': agent['name'], 'workspace': agent['workspace'],
            'executors': agent['executors'], 'labels': agent['labels'], 'mode': 'EXCLUSIVE',
            'launcher': 'hudson.plugins.sshslaves.SSHLauncher', 'host': agent['host'],
            'credentialId': agent['credential_id'], 'credentialUser': agent['username'],
            'verification': 'ManuallyProvidedKeyVerificationStrategy', 'hostKeyMatches': True,
        }
        mismatches += ['Linux agent ' + key for key, value in expected_agent.items()
                       if report.get('linuxAgent', {}).get(key) != value]
    if report.get('failedPlugins') or report.get('lastLoaded', 0) <= 0:
        mismatches.append('JCasC/plugin startup')
    if not any(source in item for item in report.get('sources', [])):
        mismatches.append('JCasC source')
    password_source = Path('/etc/jenkins-lab/secrets/admin-password').read_text()
    if password_source.startswith('#jbcrypt:'):
        users = [ET.parse(path).getroot() for path in (home / 'users').glob('*/config.xml')]
        admin = next((user for user in users if user.findtext('id') == settings['admin_id']), None)
        if admin is None or admin.findtext('./properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash') != password_source:
            mismatches.append('existing admin password preservation')
    if mismatches:
        raise RuntimeError('JCasC verification failed: ' + ', '.join(mismatches))
    return report


if __name__ == '__main__':
    verify(sys.argv[1], json.loads(Path(sys.argv[2]).read_text()), sys.argv[3])
    print('JCasC loaded; security, admin, credential reference, URL, English and zero executors verified')
