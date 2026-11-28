#!/usr/bin/env python3
"""Milestone 5: inspect non-secret configuration; never export credentials."""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

home = Path('/var/lib/jenkins')
root = ET.parse(home / 'config.xml').getroot()
realm = root.find('securityRealm')
authorization = root.find('authorizationStrategy')
users = []
for user_file in sorted((home / 'users').glob('*/config.xml')):
    user = ET.parse(user_file).getroot()
    if user.find('.//hudson.security.HudsonPrivateSecurityRealm_-Details') is not None:
        users.append(user.findtext('id'))
credential_ids = []
credential_file = home / 'credentials.xml'
if credential_file.exists():
    credential_root = ET.parse(credential_file).getroot()
    credential_ids = [node.text for node in credential_root.findall('.//id')]
print(json.dumps({
    'realm': realm.get('class') if realm is not None else None,
    'authorization': authorization.get('class') if authorization is not None else None,
    'denyAnonymousReadAccess': authorization.findtext('denyAnonymousReadAccess') if authorization is not None else None,
    'permissions': [node.text for node in authorization.findall('permission')] if authorization is not None else [],
    'local_users': users,
    'credential_ids': credential_ids,
}, indent=2))
