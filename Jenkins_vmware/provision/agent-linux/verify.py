#!/usr/bin/env python3
"""Milestone 6: require a fresh live-node report and a successful agent pipeline."""
import json
from pathlib import Path
import sys
import time

path = Path('/var/lib/jenkins/milestone-6-linux-agent.json')
if not path.exists():
    print('Waiting for Linux agent runtime reporting')
    sys.exit(1)
report = json.loads(path.read_text())
if time.time() * 1000 - report['updatedAt'] > 15000:
    print('Waiting for a fresh Linux agent status report')
    sys.exit(1)
if report['controllerExecutors'] != 0:
    print('Controller executors must remain zero')
    sys.exit(2)
if report['result'] in ('FAILURE', 'ABORTED', 'UNSTABLE') and report['buildInput'] == report['expectedInput']:
    print('Linux smoke pipeline failed; inspect job ' + report['job'])
    sys.exit(2)
if not report['online']:
    print('Waiting for SSH agent: ' + str(report.get('offlineReason') or 'connecting'))
    sys.exit(1)
if report['result'] != 'SUCCESS' or report['buildInput'] != report['expectedInput']:
    print('Waiting for smoke pipeline ' + report['job'])
    sys.exit(1)
print('%s online over SSH; %s #%s SUCCESS; controller executors = 0' %
      (report['node'], report['job'], report['buildNumber']))
