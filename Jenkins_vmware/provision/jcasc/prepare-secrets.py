#!/usr/bin/env python3
"""Milestone 5: preserve an existing password hash, or bootstrap a fresh admin.

Secret values never leave the VM and are never printed. Files are created once.
"""
import json
import os
from pathlib import Path
import secrets
import sys
import xml.etree.ElementTree as ET

admin_id = sys.argv[1]
home = Path('/var/lib/jenkins')
secret_dir = Path('/etc/jenkins-lab/secrets')
existing = None
for path in (home / 'users').glob('*/config.xml'):
    user = ET.parse(path).getroot()
    if user.findtext('id') == admin_id:
        existing = user
        break
password_hash = existing.findtext('./properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash') if existing is not None else None
if existing is not None and not password_hash:
    raise SystemExit('Existing user does not have a local password; reconcile before applying JCasC')
if password_hash and not password_hash.startswith('#jbcrypt:'):
    raise SystemExit('Unsupported existing password encoding; no credentials changed')
values = {
    'admin-password': password_hash or secrets.token_urlsafe(32),
    'admin-name': (existing.findtext('fullName') if existing is not None else None) or admin_id,
    'admin-description': (existing.findtext('description') if existing is not None else None) or '',
    'webhook-token': secrets.token_urlsafe(48),
}
changed = False
for name, value in values.items():
    target = secret_dir / name
    if target.is_symlink():
        raise SystemExit('Secret path must not be a symlink')
    if not target.exists():
        with os.fdopen(os.open(str(target), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600), 'w') as stream:
            stream.write(value)
        changed = True
    elif name == 'admin-password' and password_hash:
        stored = target.read_text()
        if stored.startswith('#jbcrypt:') and stored != password_hash:
            raise SystemExit('Existing admin password changed; reconcile the protected secret before applying JCasC')
print(json.dumps({'changed': changed, 'existing_admin_preserved': password_hash is not None}))
