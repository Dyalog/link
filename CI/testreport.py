#!/usr/bin/env python3
"""Generate a self-contained HTML dashboard of the Link test results of one Jenkins build, or of a local results/ folder.

  CI/testreport.py http://jenkins.dyalog.bramley/job/link-testing/job/jenkins-tests/1/    [-o report.html] [--open]
  CI/testreport.py results/                                                                [-o report.html] [--open]

The report shows the test matrix (every test against every interpreter and watcher mode, colour coded), the failures
grouped by message, and one row per interpreter with links to its log and aplcore. Everything is in one HTML file
with no external dependencies, so it can be mailed or archived with the build.

Jenkins: the archived results/junit-*.xml reports of the build (as written by Test/WriteJUnit.aplf and CI/runlinktests)
are the primary source, because they keep the difference between a failed assertion and an error, and say which start
of the interpreter (attempt) a result comes from. The Jenkins test report JSON adds how long each test has been failing,
and the job's build history gives the trend. A build with no archived reports falls back to the test report JSON alone.
Set JENKINS_USER and JENKINS_TOKEN if the server does not allow anonymous reads.

Local: reads results/junit-*.xml as left by CI/runlinktests and links to the logs beside them.

Only the Python standard library is used (Python 3.8 or later).
"""

import argparse
import base64
import concurrent.futures
import datetime
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
import xml.etree.ElementTree as ET

# Platform order and labels (the order of CI/testmatrix [agents]); an unknown platform goes last, labelled by its id
PLATFORMS = [
    ('win', 'Windows'),
    ('mac', 'macOS Intel'),
    ('mac_arm', 'macOS ARM'),
    ('linux', 'Linux (Docker)'),
    ('linux_public', 'Linux (public image)'),
    ('linux_native', 'Linux (native)'),
    ('linux_arm', 'Linux arm64'),
    ('pi', 'Raspberry Pi'),
    ('aix', 'AIX'),
]
EDITION_ORDER = ['32C', '32U', '64C', '64U']
MODE_ORDER = ['watcher', 'crawler']

# results/junit-<label>[.<n>][.crash|.exit|.missing|.infra].xml
REPORT_RE = re.compile(r'^junit-(?P<label>.+?)(?:\.(?P<attempt>\d+))?(?:\.(?P<kind>crash|exit|missing|infra))?\.xml$')
# <platform>_<version without dot>[_<bits><C|U>]
LABEL_RE = re.compile(r'^(?P<platform>[a-z][a-z0-9_]*?)_(?P<version>\d{2,3})(?:_(?P<edition>\d\d[CU]))?$')
CASE_RE = re.compile(r'^(?P<test>\w+?)(?: \((?P<mode>\w+)\))?$')
INTERP_RE = re.compile(r'^interpreter \((?P<what>.*)\)$')
INTERRUPTED_RE = re.compile(r'^(?P<test>test_\w+) with (?P<mode>\w+)$')


def die(msg):
    sys.exit('testreport: ' + msg)


# ----------------------------------------------------------------------------------------------------------------------
# Fetching from Jenkins

class Jenkins:
    def __init__(self, build_url):
        self.build_url = build_url
        self.job_url = re.sub(r'\d+/$', '', build_url)  # .../job/jenkins-tests/1/  ->  .../job/jenkins-tests/
        self.auth = None
        if os.environ.get('JENKINS_USER') and os.environ.get('JENKINS_TOKEN'):
            token = base64.b64encode((os.environ['JENKINS_USER'] + ':' + os.environ['JENKINS_TOKEN']).encode()).decode()
            self.auth = 'Basic ' + token

    def get(self, url, binary=False):
        req = urllib.request.Request(url, headers={'User-Agent': 'link-testreport'})
        if self.auth:
            req.add_header('Authorization', self.auth)
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read()
        return data if binary else data.decode('utf-8', 'replace')

    def get_json(self, url):
        return json.loads(self.get(url))


def normalise_build_url(url):
    """Accept the build page, its testReport/, console, ... and return the build URL with a trailing slash"""
    url = url.strip()
    if not re.match(r'^https?://', url):
        die('not a Jenkins build URL: ' + url)
    m = re.match(r'^(.*?/job/[^/]+(?:/job/[^/]+)*/\d+/)', url)
    if not m:
        m = re.match(r'^(.*?/\d+/)', url)
    if not m:
        die('cannot find the build number in ' + url)
    return m.group(1)


def load_jenkins(build_url, quiet=False):
    j = Jenkins(build_url)
    log = (lambda *a: None) if quiet else (lambda *a: print(*a, file=sys.stderr))

    log('fetching build', build_url)
    tree = ('tree=number,result,building,duration,timestamp,fullDisplayName,url,artifacts[relativePath],'
            'actions[causes[shortDescription],lastBuiltRevision[SHA1,branch[name]],remoteUrls,'
            'failCount,totalCount,skipCount,parameters[name,value]]')
    try:
        build = j.get_json(build_url + 'api/json?' + tree)
    except urllib.error.HTTPError as e:
        die('cannot read %sapi/json: HTTP %s %s' % (build_url, e.code, e.reason))
    except urllib.error.URLError as e:
        die('cannot reach %s: %s' % (build_url, e.reason))

    meta = {
        'source': 'jenkins',
        'name': build.get('fullDisplayName') or build_url,
        'number': build.get('number'),
        'result': 'RUNNING' if build.get('building') else (build.get('result') or 'UNKNOWN'),
        'url': build_url,
        'job_url': j.job_url,
        'timestamp': build.get('timestamp'),
        'duration': build.get('duration'),
        'branch': None, 'sha': None, 'remote': None, 'cause': None, 'params': {},
    }
    for a in build.get('actions') or []:
        if a.get('causes'):
            meta['cause'] = '; '.join(c.get('shortDescription', '') for c in a['causes'])
        if a.get('lastBuiltRevision'):
            rev = a['lastBuiltRevision']
            meta['sha'] = rev.get('SHA1')
            if rev.get('branch'):
                meta['branch'] = rev['branch'][0].get('name')
            if a.get('remoteUrls'):
                meta['remote'] = a['remoteUrls'][0]
        if a.get('parameters'):
            meta['params'] = {p['name']: p.get('value') for p in a['parameters'] if 'name' in p}

    # The Jenkins test report: age and failedSince per case, and the pipeline block names that make up the case URLs
    log('fetching test report')
    ages = {}
    blocks = {}
    report = None
    try:
        report = j.get_json(build_url + 'testReport/api/json?depth=2')
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise
        log('no test report on this build (HTTP 404)')
    if report:
        for suite in report.get('suites') or []:
            names = suite.get('enclosingBlockNames') or []
            blocks[suite.get('name')] = ''.join(n + ' / ' for n in reversed(names))
            for c in suite.get('cases') or []:
                ages[(c.get('className'), c.get('name'))] = (c.get('age'), c.get('failedSince'))

    # The archived JUnit reports: results/junit-*.xml
    artifacts = [a['relativePath'] for a in build.get('artifacts') or []]
    reports = [a for a in artifacts if re.match(r'^results/junit-.*\.xml$', a)]
    logs = {os.path.basename(a): build_url + 'artifact/' + a for a in artifacts if a.endswith('.log')}
    cores = {os.path.basename(a): build_url + 'artifact/' + a for a in artifacts if '.aplcore' in a}
    files = []
    if reports:
        log('fetching %d JUnit reports' % len(reports))
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            def fetch(path):
                return path, j.get(build_url + 'artifact/' + path, binary=True)
            for path, data in pool.map(fetch, reports):
                files.append((os.path.basename(path), data))
        suites = parse_reports(files)
    elif report:
        log('no archived JUnit reports: using the Jenkins test report only')
        suites = suites_from_jenkins_report(report)
    else:
        die('this build has neither archived JUnit reports nor a test report')

    def case_url(classname, name):
        return build_url + 'testReport/(root)/' + urllib.parse.quote(classname) + '/' + safe_name(blocks.get(classname, '') + name) + '/'

    def suite_url(classname):
        return build_url + 'testReport/(root)/' + urllib.parse.quote(classname) + '/'

    for s in suites:
        for c in s['cases']:
            age, since = ages.get((s['label'], c['name']), (None, None))
            c['age'], c['since'] = age, since
            c['url'] = case_url(s['label'], c['name'])
        s['url'] = suite_url(s['label'])
        s['log'] = logs.get(s['label'] + '.log')
        s['cores'] = [u for n, u in sorted(cores.items()) if n.startswith(s['label'] + '.')]

    # Trend: the job's recent builds
    history = []
    try:
        job = j.get_json(j.job_url + 'api/json?tree=builds[number,result,building,timestamp,duration,url,actions[failCount,totalCount,skipCount]]{0,30}')
        for b in job.get('builds') or []:
            counts = next((a for a in b.get('actions') or [] if 'totalCount' in a), {})
            history.append({
                'number': b.get('number'), 'result': 'RUNNING' if b.get('building') else (b.get('result') or 'UNKNOWN'),
                'timestamp': b.get('timestamp'), 'duration': b.get('duration'), 'url': b.get('url'),
                'fail': counts.get('failCount'), 'total': counts.get('totalCount'), 'skip': counts.get('skipCount'),
            })
        history.sort(key=lambda b: b['number'] or 0)
    except Exception as e:  # the trend is a nicety: never fail the report for it
        log('cannot read the build history:', e)
    return meta, suites, history


def safe_name(name):
    """Jenkins' URL-safe form of a test name: anything but letters and digits becomes _"""
    return re.sub(r'[^A-Za-z0-9]', '_', name)


def suites_from_jenkins_report(report):
    """Fallback when the JUnit files are not archived: the Jenkins JSON (which does not distinguish failure from error)"""
    suites = {}
    for suite in report.get('suites') or []:
        label = suite.get('name')
        s = suites.setdefault(label, new_suite(label))
        for c in suite.get('cases') or []:
            status = {'PASSED': 'passed', 'FIXED': 'passed', 'SKIPPED': 'skipped'}.get(c.get('status'), 'failed')
            msg = c.get('errorDetails') or ''
            if status == 'failed' and not msg.startswith('assertion failed') and not re.match(r'^link issue', msg):
                if ':' in msg and not msg.startswith('assert'):
                    status = 'error'   # the best guess we have: assertions say "assertion failed: ..."
            add_case(s, c.get('name') or '', status, msg, (c.get('errorStackTrace') or '').strip(), c.get('duration') or 0, attempt=None, kind=None)
    return list(suites.values())


# ----------------------------------------------------------------------------------------------------------------------
# Parsing JUnit reports

def new_suite(label):
    m = LABEL_RE.match(label)
    platform, version, edition = (m.group('platform'), m.group('version'), m.group('edition')) if m else (label, '', None)
    return {
        'label': label, 'platform': platform, 'version': version[:-1] + '.' + version[-1] if version else '',
        'edition': edition, 'cases': [], 'events': [], 'attempts': 0, 'url': None, 'log': None, 'cores': [],
    }


def add_case(suite, name, status, message, detail, time, attempt, kind):
    """detail: the text of the <failure>/<error> element (the error and the stack it happened on, or the end of the log
    for an interpreter event) - what Jenkins calls the stack trace"""
    m = INTERP_RE.match(name)
    if m:  # interpreter (setup) | interpreter (missing) | interpreter (exit) | interpreter (no report) | interpreter (test_x with mode)
        what = m.group('what')
        mi = INTERRUPTED_RE.match(what)
        suite['events'].append({
            'name': name, 'what': what, 'kind': kind or event_kind(what, message), 'status': status, 'msg': message, 'detail': detail,
            'attempt': attempt, 'test': mi.group('test') if mi else None, 'mode': mi.group('mode') if mi else None,
        })
        return
    m = CASE_RE.match(name)
    test, mode = (m.group('test'), m.group('mode') or '') if m else (name, '')
    suite['cases'].append({'name': name, 'test': test, 'mode': mode, 'status': status, 'msg': message, 'detail': detail,
                           'time': time, 'attempt': attempt})


def event_kind(what, message):
    what, message = what.lower(), message.lower()
    if what == 'setup':
        return 'infra'
    if what == 'missing':
        return 'missing'
    if what == 'exit':
        return 'exit'
    if 'no report' in what or 'without writing' in message:
        return 'noreport'
    if 'hung' in message:
        return 'hung'
    if 'aplcore' in message:
        return 'aplcore'
    if 'untrapped' in message:
        return 'aplerror'
    return 'crash'


def parse_reports(files):
    """files: [(basename, bytes)] -> suites, one per interpreter label, with cases and interpreter events"""
    suites = {}
    for name, data in sorted(files):
        m = REPORT_RE.match(name)
        if not m:
            continue
        label, attempt, kind = m.group('label'), m.group('attempt'), m.group('kind')
        attempt = int(attempt) if attempt else None
        try:
            root = ET.fromstring(data)
        except ET.ParseError as e:
            print('testreport: cannot parse %s: %s' % (name, e), file=sys.stderr)
            continue
        for ts in ([root] if root.tag == 'testsuite' else root.iter('testsuite')):
            s = suites.setdefault(label, new_suite(label))
            if attempt and kind in (None, 'crash'):
                s['attempts'] = max(s['attempts'], attempt)
            for tc in ts.iter('testcase'):
                status, msg, detail = 'passed', '', ''
                for child in tc:
                    if child.tag in ('failure', 'error', 'skipped'):
                        status = {'failure': 'failed'}.get(child.tag, child.tag)
                        detail = (child.text or '').strip()
                        msg = child.get('message') or detail.split('\n', 1)[0]
                        break
                # the .crash/.exit/.missing/.infra files say what happened more reliably than the message does
                event_kind_hint = {'crash': None, 'exit': 'exit', 'missing': 'missing', 'infra': 'infra'}.get(kind)
                if kind == 'crash':
                    event_kind_hint = event_kind(INTERP_RE.match(tc.get('name', '')).group('what') if INTERP_RE.match(tc.get('name', '')) else '', msg)
                add_case(s, tc.get('name', ''), status, msg, detail, float(tc.get('time') or 0), attempt, event_kind_hint)
    return list(suites.values())


def load_local(folder):
    folder = os.path.abspath(folder)
    if not os.path.isdir(folder):
        die('not a folder: ' + folder)
    files = []
    for name in os.listdir(folder):
        if REPORT_RE.match(name):
            with open(os.path.join(folder, name), 'rb') as f:
                files.append((name, f.read()))
    if not files:
        die('no junit-*.xml reports in ' + folder)
    suites = parse_reports(files)
    names = set(os.listdir(folder))
    for s in suites:
        for c in s['cases']:
            c['age'], c['since'], c['url'] = None, None, None
        s['log'] = os.path.join(folder, s['label'] + '.log') if s['label'] + '.log' in names else None
        s['cores'] = [os.path.join(folder, n) for n in sorted(names) if n.startswith(s['label'] + '.') and '.aplcore' in n]
    newest = max(os.path.getmtime(os.path.join(folder, n)) for n, _ in files)
    meta = {
        'source': 'local', 'name': folder, 'number': None, 'result': None, 'url': None, 'job_url': None,
        'timestamp': int(newest * 1000), 'duration': None, 'branch': None, 'sha': None, 'remote': None, 'cause': None, 'params': {},
    }
    return meta, suites, []


# ----------------------------------------------------------------------------------------------------------------------
# Building the report model

def platform_key(p):
    ids = [i for i, _ in PLATFORMS]
    return (ids.index(p) if p in ids else len(ids), p)


def version_key(v):
    try:
        return tuple(int(x) for x in v.split('.'))
    except ValueError:
        return (999,)


def edition_key(e):
    return (EDITION_ORDER.index(e) if e in EDITION_ORDER else len(EDITION_ORDER), e or '')


def mode_key(m):
    return (MODE_ORDER.index(m) if m in MODE_ORDER else len(MODE_ORDER), m)


def build_model(meta, suites, history, out_dir):
    labels = dict(PLATFORMS)
    suites.sort(key=lambda s: (platform_key(s['platform']), version_key(s['version']), edition_key(s['edition'])))
    tests = sorted({c['test'] for s in suites for c in s['cases']} | {e['test'] for s in suites for e in s['events'] if e['test']})
    modes = sorted({c['mode'] for s in suites for c in s['cases']} | {e['mode'] for s in suites for e in s['events'] if e['mode']}, key=mode_key)

    def link(path):  # local files are linked relative to the report
        if not path:
            return None
        if meta['source'] == 'jenkins':
            return path
        return urllib.parse.quote(os.path.relpath(path, out_dir).replace(os.sep, '/'))

    interps, cells, cases, events = [], [], [], []
    for s in suites:
        if s['edition'] is None:  # <platform>_<version>.infra.xml: the whole platform/version cell could not run
            for e in s['events']:
                events.append(dict(e, interp=None, group='%s %s' % (s['platform'], s['version']), platform=s['platform'],
                                   version=s['version'], label=s['label'], url=s['url']))
            continue
        idx = len(interps)
        imodes = sorted({c['mode'] for c in s['cases']} | {e['mode'] for e in s['events'] if e['mode']}, key=mode_key) or ['']
        counts = {'passed': 0, 'failed': 0, 'error': 0, 'skipped': 0}
        for c in s['cases']:
            counts[c['status']] = counts.get(c['status'], 0) + 1
            cases.append({'i': idx, 't': tests.index(c['test']), 'm': c['mode'], 's': c['status'], 'msg': c['msg'], 'd': c['detail'],
                          'time': c['time'], 'age': c['age'], 'since': c['since'], 'url': c['url'], 'attempt': c['attempt']})
        for e in s['events']:
            events.append(dict(e, interp=idx, group=None, platform=s['platform'], version=s['version'], label=s['label'], url=s['url']))
        interps.append({
            'id': s['label'], 'platform': s['platform'], 'platform_label': labels.get(s['platform'], s['platform']),
            'version': s['version'], 'edition': s['edition'] or '', 'bits': (s['edition'] or '')[:2],
            'unicode': (s['edition'] or '').endswith('U'), 'modes': imodes, 'attempts': s['attempts'],
            'log': link(s['log']), 'cores': [link(c) for c in s['cores']], 'url': s['url'],
            'time': round(sum(c['time'] for c in s['cases']), 1), 'counts': counts, 'ntests': len(s['cases']),
        })
    platforms = []
    for pid in sorted({i['platform'] for i in interps} | {e['platform'] for e in events}, key=platform_key):
        platforms.append({'id': pid, 'label': labels.get(pid, pid)})
    return {
        'meta': meta, 'generated': datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
        'platforms': platforms, 'interps': interps, 'tests': tests, 'modes': modes, 'cases': cases, 'events': events,
        'history': history,
    }


# ----------------------------------------------------------------------------------------------------------------------
# HTML

CSS = r"""
:root {
  color-scheme: light;
  --bg: #f9f9f7; --surface: #fcfcfb; --ink: #0b0b0b; --ink2: #52514e; --muted: #898781;
  --grid: #e1e0d9; --line: #c3c2b7; --border: rgba(11,11,11,.10); --accent: #2a78d6; --accent-soft: #cde2fb;
  --good: #0ca30c; --good-text: #006300; --warn: #fab219; --serious: #ec835a; --critical: #d03b3b;
  --notrun: #e6e5df; --notrun-ink: #898781; --shadow: 0 8px 24px rgba(11,11,11,.12);
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
    --bg: #0d0d0d; --surface: #1a1a19; --ink: #ffffff; --ink2: #c3c2b7; --muted: #898781;
    --grid: #2c2c2a; --line: #383835; --border: rgba(255,255,255,.10); --accent: #3987e5; --accent-soft: #184f95;
    --good-text: #0ca30c; --notrun: #262624; --notrun-ink: #898781; --shadow: 0 8px 24px rgba(0,0,0,.5);
  }
}
:root[data-theme="dark"] {
  color-scheme: dark;
  --bg: #0d0d0d; --surface: #1a1a19; --ink: #ffffff; --ink2: #c3c2b7; --muted: #898781;
  --grid: #2c2c2a; --line: #383835; --border: rgba(255,255,255,.10); --accent: #3987e5; --accent-soft: #184f95;
  --good-text: #0ca30c; --notrun: #262624; --notrun-ink: #898781; --shadow: 0 8px 24px rgba(0,0,0,.5);
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { background: var(--bg); color: var(--ink); font: 14px/1.45 system-ui, -apple-system, "Segoe UI", sans-serif; padding: 0 16px 48px; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
code, .mono { font-family: ui-monospace, "Cascadia Code", Menlo, Consolas, monospace; font-size: 12.5px; }
.wrap { max-width: 1400px; margin: 0 auto; }
h1 { font-size: 22px; font-weight: 650; margin: 0; letter-spacing: -.01em; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
h2 { font-size: 15px; font-weight: 650; margin: 0 0 10px; color: var(--ink); display: flex; align-items: baseline; gap: 10px; }
h2 small { font-weight: 400; color: var(--ink2); font-size: 13px; }
header { padding: 26px 0 16px; display: flex; justify-content: space-between; gap: 16px; flex-wrap: wrap; align-items: flex-start; }
.meta { color: var(--ink2); font-size: 13px; margin-top: 6px; display: flex; gap: 6px 14px; flex-wrap: wrap; }
.meta b { color: var(--ink); font-weight: 550; }
.links { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.btn { display: inline-block; border: 1px solid var(--border); background: var(--surface); color: var(--ink); padding: 6px 11px; border-radius: 8px; font-size: 13px; line-height: 1.2; cursor: pointer; }
.btn:hover { border-color: var(--line); text-decoration: none; }
.badge { display: inline-flex; align-items: center; gap: 6px; padding: 3px 10px; border-radius: 999px; font-size: 12.5px; font-weight: 600; letter-spacing: .02em; color: #fff; }
.badge.SUCCESS { background: var(--good); } .badge.UNSTABLE { background: var(--warn); color: #0b0b0b; }
.badge.FAILURE { background: var(--critical); } .badge.ABORTED, .badge.UNKNOWN, .badge.NOT_BUILT { background: var(--muted); }
.badge.RUNNING { background: var(--accent); }
.card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 16px; }
section { margin-top: 18px; }
.kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; }
.kpi { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 12px 14px; min-height: 84px; display: flex; flex-direction: column; justify-content: space-between; }
.kpi .l { color: var(--ink2); font-size: 12.5px; }
.kpi .v { font-size: 28px; font-weight: 650; letter-spacing: -.02em; line-height: 1.1; margin-top: 4px; display: flex; align-items: baseline; gap: 8px; }
.kpi .v small { font-size: 13px; font-weight: 400; color: var(--ink2); letter-spacing: 0; }
.kpi .sub { color: var(--ink2); font-size: 12px; margin-top: 6px; }
.kpi.trend { grid-column: span 2; }
.dot { display: inline-block; width: 10px; height: 10px; border-radius: 3px; vertical-align: -1px; margin-right: 6px; }
.bar { display: flex; height: 6px; border-radius: 3px; overflow: hidden; background: var(--notrun); gap: 1px; }
.bar i { display: block; height: 100%; }
.st-passed { background: var(--good); } .st-failed { background: var(--critical); } .st-error { background: var(--serious); }
.st-skipped { background: var(--warn); } .st-interrupted { background: var(--critical); } .st-notrun { background: var(--notrun); }

/* filters */
.filters { display: flex; gap: 8px 14px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; font-size: 13px; color: var(--ink2); }
.filters label { display: inline-flex; align-items: center; gap: 5px; cursor: pointer; }
.filters input[type=search] { border: 1px solid var(--line); border-radius: 8px; padding: 5px 9px; background: var(--surface); color: var(--ink); font: inherit; min-width: 220px; }
.chips { display: inline-flex; gap: 4px; flex-wrap: wrap; }
.chip { border: 1px solid var(--line); border-radius: 999px; padding: 2px 9px; font-size: 12px; cursor: pointer; background: var(--surface); color: var(--ink); user-select: none; }
.chip.off { opacity: .45; text-decoration: line-through; }
.legend { display: flex; gap: 12px; flex-wrap: wrap; font-size: 12px; color: var(--ink2); margin-top: 10px; align-items: center; }
.legend .sw { display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 16px; border-radius: 3px; font-size: 11px; font-weight: 700; color: #fff; margin-right: 5px; vertical-align: -3px; }

/* matrix */
.scroller { overflow: auto; max-height: 78vh; border: 1px solid var(--border); border-radius: 10px; background: var(--surface); }
table.matrix { border-collapse: separate; border-spacing: 0; font-size: 12px; }
table.matrix th, table.matrix td { padding: 0; border-bottom: 1px solid var(--grid); border-right: 1px solid var(--grid); background: var(--surface); }
table.matrix thead th { position: sticky; z-index: 3; background: var(--surface); font-weight: 500; color: var(--ink2); white-space: nowrap; text-align: center; }
table.matrix thead tr:nth-child(1) th { top: 0; height: 26px; font-weight: 600; color: var(--ink); border-bottom-color: var(--line); }
table.matrix thead tr:nth-child(2) th { top: 26px; height: 24px; font-size: 10.5px; overflow: hidden; text-overflow: clip; max-width: 24px; }
table.matrix thead tr:nth-child(2) th[colspan]:not([colspan="1"]) { max-width: none; }
table.matrix thead tr:nth-child(3) th { top: 50px; height: 58px; vertical-align: bottom; }
table.matrix thead tr:nth-child(3) th .vt { writing-mode: vertical-rl; transform: rotate(180deg); display: inline-block; padding: 4px 0; font-size: 11px; letter-spacing: .02em; }
table.matrix thead tr:nth-child(3) th .ev { display: block; height: 14px; line-height: 14px; font-size: 10px; font-weight: 700; color: #fff; background: var(--critical); border-radius: 3px; margin: 0 2px 3px; }
table.matrix thead tr:nth-child(3) th .ev.missing { background: var(--serious); color: #0b0b0b; }
table.matrix thead tr:nth-child(3) th .ev.exit { background: var(--warn); color: #0b0b0b; }
table.matrix th.rowhead, table.matrix td.rowhead { position: sticky; left: 0; z-index: 2; text-align: left; padding: 0 10px; min-width: 170px; font-weight: 500; color: var(--ink); border-right: 1px solid var(--line); }
table.matrix thead th.rowhead { z-index: 4; }
table.matrix td.rowhead .mono { color: var(--ink); }
table.matrix td.sum { position: sticky; right: 0; z-index: 2; padding: 0 10px; min-width: 120px; white-space: nowrap; color: var(--ink2); border-left: 1px solid var(--line); font-variant-numeric: tabular-nums; box-shadow: -8px 0 8px -8px rgba(0,0,0,.35); }
table.matrix thead th.sum { position: sticky; right: 0; z-index: 4; border-left: 1px solid var(--line); box-shadow: -8px 0 8px -8px rgba(0,0,0,.35); }
table.matrix td.sum .bar { width: 64px; display: inline-flex; vertical-align: middle; margin-left: 8px; }
table.matrix td.c { width: 24px; height: 24px; text-align: center; vertical-align: middle; }
table.matrix tr.grp td.rowhead { background: var(--bg); color: var(--ink2); font-size: 11.5px; text-transform: uppercase; letter-spacing: .06em; height: 22px; }
table.matrix tr.grp td { background: var(--bg); }
.cell { position: relative; display: flex; align-items: center; justify-content: center; width: 20px; height: 20px; margin: 2px; border-radius: 4px; font-size: 11px; font-weight: 700; line-height: 1; color: #fff; cursor: pointer; border: 0; padding: 0; font-family: inherit; }
.cell:hover, .cell:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.cell.passed { background: var(--good); } .cell.failed { background: var(--critical); }
.cell.error { background: var(--serious); color: #0b0b0b; } .cell.skipped { background: var(--warn); color: #0b0b0b; }
.cell.interrupted { background: var(--critical); }
.cell.notrun { background: var(--notrun); color: var(--notrun-ink); background-image: repeating-linear-gradient(135deg, transparent 0 3px, var(--grid) 3px 4px); }
.cell.new { box-shadow: inset 0 0 0 2px var(--surface), inset 0 0 0 4px var(--critical); }
.cell.dim { opacity: .25; }
table.matrix tbody tr:hover td { background: var(--bg); }
table.matrix tbody td.c.hl, table.matrix thead th.hl { background: var(--accent-soft); }
table.matrix tbody tr:hover td.rowhead { color: var(--accent); }
table.matrix tr.hidden, table.matrix .hidecol { display: none; }
.empty { color: var(--ink2); padding: 20px; text-align: center; }

/* groups */
.grp-list { display: flex; flex-direction: column; gap: 8px; }
details.g { border: 1px solid var(--border); border-radius: 10px; background: var(--surface); }
details.g summary { list-style: none; cursor: pointer; padding: 10px 14px; display: grid; grid-template-columns: 44px 84px 1fr auto; gap: 12px; align-items: center; }
details.g summary::-webkit-details-marker { display: none; }
details.g summary .n { font-size: 18px; font-weight: 650; text-align: right; font-variant-numeric: tabular-nums; }
details.g summary .msg { color: var(--ink); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
details.g[open] summary .msg { white-space: normal; }
details.g summary .where { color: var(--ink2); font-size: 12px; white-space: nowrap; }
details.g .body { padding: 4px 14px 14px 140px; color: var(--ink2); font-size: 13px; }
details.g .body .full { white-space: pre-wrap; word-break: break-word; color: var(--ink); margin-bottom: 10px; }
.tag { display: inline-block; border-radius: 6px; padding: 1px 7px; font-size: 11.5px; font-weight: 600; color: #fff; text-transform: capitalize; }
.tag.failed, .tag.interrupted, .tag.crash, .tag.hung, .tag.aplcore, .tag.aplerror, .tag.noreport, .tag.infra { background: var(--critical); }
.tag.error, .tag.missing { background: var(--serious); color: #0b0b0b; } .tag.exit, .tag.skipped { background: var(--warn); color: #0b0b0b; }
.tag.passed { background: var(--good); }
.tag.ok { background: var(--good); }
.pills { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
.pill { border: 1px solid var(--grid); border-radius: 6px; padding: 1px 7px; font-size: 11.5px; color: var(--ink); background: var(--bg); }
.pill a { color: inherit; }

/* interpreters table */
table.plain { width: 100%; border-collapse: collapse; font-size: 13px; }
table.plain th { text-align: left; font-weight: 550; color: var(--ink2); font-size: 12px; padding: 6px 10px; border-bottom: 1px solid var(--line); white-space: nowrap; }
table.plain td { padding: 7px 10px; border-bottom: 1px solid var(--grid); vertical-align: top; }
table.plain td.num, table.plain th.num { text-align: right; font-variant-numeric: tabular-nums; }
table.plain tr.bad td:first-child { box-shadow: inset 3px 0 0 var(--critical); }
table.plain .bar { width: 90px; margin-top: 6px; }
.tablewrap { overflow-x: auto; }

/* trend */
.spark { display: flex; align-items: flex-end; gap: 3px; height: 44px; margin-top: 8px; }
.spark a { display: block; flex: 1 1 0; max-width: 18px; min-width: 6px; border-radius: 3px 3px 0 0; position: relative; }
.spark a.cur { outline: 2px solid var(--ink); outline-offset: 1px; }

/* tooltip & detail */
#tip { position: fixed; z-index: 50; pointer-events: none; transition: left .06s, top .06s; background: var(--ink); color: var(--bg); padding: 8px 10px; border-radius: 8px; font-size: 12.5px; max-width: 460px; box-shadow: var(--shadow); display: none; line-height: 1.4; }
#tip b { font-weight: 650; } #tip .m { opacity: .8; } #tip .msg { margin-top: 4px; white-space: pre-wrap; word-break: break-word; font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 12px; }
#detail { position: fixed; right: 16px; bottom: 16px; width: min(560px, calc(100vw - 32px)); max-height: 60vh; overflow: auto; z-index: 40; box-shadow: var(--shadow); display: none; }
#detail.show { display: block; }
#detail .hd { display: flex; justify-content: space-between; gap: 10px; align-items: flex-start; }
#detail h3 { margin: 0 0 6px; font-size: 15px; }
#detail .kv { display: grid; grid-template-columns: 96px 1fr; gap: 4px 10px; font-size: 13px; color: var(--ink2); margin-top: 8px; }
#detail .kv div:nth-child(even) { color: var(--ink); }
#detail .msg { white-space: pre-wrap; word-break: break-word; background: var(--bg); border: 1px solid var(--grid); border-radius: 8px; padding: 8px 10px; margin-top: 10px; }
pre.stack { white-space: pre-wrap; word-break: break-word; font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 12px; line-height: 1.4; color: var(--ink);
  background: var(--bg); border: 1px solid var(--grid); border-radius: 8px; padding: 8px 10px; margin: 8px 0 0; }
.note { color: var(--ink2); font-size: 12px; margin-top: 4px; }
#detail .x { border: 0; background: transparent; color: var(--ink2); font-size: 20px; line-height: 1; cursor: pointer; padding: 0 4px; }
footer { margin-top: 28px; color: var(--muted); font-size: 12px; }
@media (max-width: 700px) {
  header { padding-top: 18px; } h1 { font-size: 19px; }
  .kpi.trend { grid-column: span 1; }
  details.g summary { grid-template-columns: 36px 1fr; } details.g summary .where { grid-column: 1 / -1; white-space: normal; }
  details.g .body { padding-left: 14px; }
  table.matrix th.rowhead, table.matrix td.rowhead { min-width: 0; padding: 0 6px; }
  table.matrix td.sum, table.matrix thead th.sum { position: static; min-width: 0; box-shadow: none; }
  table.matrix td.sum .bar { display: none; }
}
@media print { .scroller { max-height: none; } #detail, #tip, .filters { display: none !important; } }
"""

JS = r"""
const D = JSON.parse(document.getElementById('data').textContent);
const $ = (s, el) => (el || document).querySelector(s);
const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmtDur = ms => { if (ms == null) return ''; const s = Math.round(ms / 1000); if (s < 90) return s + 's';
  const m = Math.round(s / 60); if (m < 90) return m + ' min'; return (m / 60).toFixed(1) + ' h'; };
const fmtSecs = s => s == null ? '' : s < 10 ? s.toFixed(2) + 's' : s < 100 ? s.toFixed(1) + 's' : Math.round(s) + 's';
const fmtDate = ms => ms ? new Date(ms).toLocaleString(undefined, {dateStyle: 'medium', timeStyle: 'short'}) : '';
const GLYPH = {passed: '✓', failed: '✕', error: '!', skipped: 's', interrupted: '‼', notrun: '–'};
const STATUS_LABEL = {passed: 'passed', failed: 'failed', error: 'error', skipped: 'skipped', interrupted: 'interrupted', notrun: 'not run'};
const EVENT_LABEL = {crash: 'crashed', hung: 'hung', aplcore: 'aplcore', aplerror: 'APL error', noreport: 'no report', exit: 'did not exit', missing: 'missing', infra: 'could not run'};
const edLabel = e => e ? e.slice(0, 2) + '-bit ' + (e.endsWith('C') ? 'Classic' : 'Unicode') : '';
const interpTitle = i => `${i.platform_label} · Dyalog ${i.version} · ${edLabel(i.edition)}`;

// ---- columns: one per interpreter × mode, grouped by platform then version
const cols = [];
D.interps.forEach((it, i) => it.modes.forEach(m => cols.push({i, it, mode: m, id: it.id + (m ? ' ' + m : '')})));
const byCell = new Map();           // `${t}|${i}|${mode}` -> case
D.cases.forEach(c => { const k = `${c.t}|${c.i}|${c.m}`; const p = byCell.get(k);
  if (!p || (c.attempt || 0) >= (p.attempt || 0)) byCell.set(k, c); });
const interrupted = new Map();      // `${i}|${mode}` -> {test event}
D.events.forEach(e => { if (e.interp != null && e.test) interrupted.set(`${e.interp}|${e.mode}|${e.test}`, e); });
const eventsByInterp = new Map();
D.events.forEach(e => { if (e.interp != null) { if (!eventsByInterp.has(e.interp)) eventsByInterp.set(e.interp, []); eventsByInterp.get(e.interp).push(e); } });
const eventsByGroup = new Map();
D.events.forEach(e => { if (e.interp == null) { const k = e.platform + ' ' + e.version; if (!eventsByGroup.has(k)) eventsByGroup.set(k, []); eventsByGroup.get(k).push(e); } });

function cellStatus(t, col) {
  const c = byCell.get(`${t}|${col.i}|${col.mode}`);
  if (c) return {s: c.s, c};
  const e = interrupted.get(`${col.i}|${col.mode}|${D.tests[t]}`);
  if (e) return {s: 'interrupted', e};
  return {s: 'notrun'};
}
const SEV = {interrupted: 5, error: 4, failed: 3, skipped: 2, notrun: 1, passed: 0};
const anyAge = D.cases.some(c => c.age != null);
// age is only meaningful against a previous build of the same job
const hasPrev = anyAge && D.history.some(b => b.number != null && D.meta.number != null && b.number < D.meta.number);

// ---- KPIs
(function kpis() {
  const counts = {passed: 0, failed: 0, error: 0, skipped: 0};
  D.cases.forEach(c => counts[c.s] = (counts[c.s] || 0) + 1);
  const total = D.cases.length;
  const ran = D.interps.filter(i => i.ntests > 0).length;
  const problems = D.events.length;
  const newFails = hasPrev ? D.cases.filter(c => c.s !== 'passed' && c.age === 1).length : null;
  const pct = total ? Math.round(100 * counts.passed / total) : 0;
  const tiles = [];
  tiles.push(`<div class="kpi"><div class="l">Test runs passed</div><div class="v">${counts.passed}<small>of ${total} · ${pct}%</small></div>
    <div class="bar" aria-hidden="true">${bar(counts, total)}</div></div>`);
  tiles.push(`<div class="kpi"><div class="l">Failed assertions</div><div class="v"><span class="dot st-failed"></span>${counts.failed}</div><div class="sub">tests whose assert did not hold</div></div>`);
  tiles.push(`<div class="kpi"><div class="l">Errors</div><div class="v"><span class="dot st-error"></span>${counts.error}</div><div class="sub">tests that stopped on an APL error</div></div>`);
  tiles.push(`<div class="kpi"><div class="l">Interpreters</div><div class="v">${ran}<small>of ${D.interps.length} ran tests</small></div>
    <div class="sub">${problems ? problems + ' interpreter problem' + (problems > 1 ? 's' : '') + ': ' + summarizeEvents() : 'no crashes, hangs or missing interpreters'}</div></div>`);
  if (newFails != null) tiles.push(`<div class="kpi"><div class="l">New failures</div><div class="v">${newFails}</div><div class="sub">not failing in the previous build</div></div>`);
  if (D.history.length > 1) tiles.push(`<div class="kpi trend"><div class="l">Failures per build <small style="color:var(--muted)">(last ${D.history.length})</small></div>${spark()}</div>`);
  $('#kpis').innerHTML = tiles.join('');
})();
function summarizeEvents() {
  const n = {}; D.events.forEach(e => n[e.kind] = (n[e.kind] || 0) + 1);
  return Object.entries(n).map(([k, v]) => `${v} ${EVENT_LABEL[k] || k}`).join(', ');
}
function bar(counts, total) {
  if (!total) return '';
  return ['passed', 'failed', 'error', 'skipped'].filter(s => counts[s]).map(s => `<i class="st-${s}" style="width:${100 * counts[s] / total}%"></i>`).join('');
}
function spark() {
  const max = Math.max(1, ...D.history.map(b => b.total || 0));
  return `<div class="spark">` + D.history.map(b => {
    const h = b.total ? Math.max(3, 40 * (b.fail || 0) / max) : 3;
    const color = {SUCCESS: 'var(--good)', UNSTABLE: 'var(--warn)', FAILURE: 'var(--critical)', RUNNING: 'var(--accent)'}[b.result] || 'var(--muted)';
    const cur = b.number === D.meta.number ? ' cur' : '';
    const t = `#${b.number} · ${b.result}` + (b.total != null ? ` · ${b.fail} failed of ${b.total}` : ' · no test report') + (b.timestamp ? ` · ${fmtDate(b.timestamp)}` : '');
    return `<a class="${cur}" href="${esc(b.url || '#')}" style="height:${h}px;background:${color}" data-tip="${esc(t)}" aria-label="${esc(t)}"></a>`;
  }).join('') + `</div>`;
}

// ---- matrix
const state = {onlyFailingRows: false, onlyFailingCols: false, onlyNew: false, q: '', platforms: new Set(D.platforms.map(p => p.id)), modes: new Set(D.modes)};
function renderMatrix() {
  const el = $('#matrix');
  if (!cols.length) { el.innerHTML = '<div class="empty">No interpreter results.</div>'; return; }
  // header tiers
  let h1 = '<tr><th class="rowhead" rowspan="3">Test</th>', h2 = '<tr>', h3 = '<tr>';
  const platGroups = groupBy(cols, c => c.it.platform);
  for (const [pid, pcols] of platGroups) {
    const p = D.platforms.find(x => x.id === pid);
    h1 += `<th colspan="${pcols.length}" data-plat="${pid}">${esc(p ? p.label : pid)}</th>`;
    for (const [ver, vcols] of groupBy(pcols, c => c.it.version)) {
      const ev = eventsByGroup.get(pid + ' ' + ver) || [];
      h2 += `<th colspan="${vcols.length}" data-plat="${pid}" ${ev.length ? `class="hasev" data-tip="${esc(ev.map(e => e.msg).join('\n'))}" style="color:var(--critical);font-weight:600"` : ''}>${esc(ver)}${ev.length ? ' ⚠' : ''}</th>`;
    }
  }
  cols.forEach((c, k) => {
    const evs = eventsByInterp.get(c.i) || [];
    const evLabel = evs.length ? (evs.length === 1 ? EVENT_LABEL[evs[0].kind] || evs[0].kind : evs.length + ' events') : '';
    const evTip = evs.map(e => `${EVENT_LABEL[e.kind] || e.kind}: ${e.msg}`).join('\n');
    const modeTag = c.it.modes.length > 1 || D.modes.length > 1 ? ' ' + (c.mode ? c.mode[0].toUpperCase() : '') : '';
    h3 += `<th data-col="${k}" data-plat="${c.it.platform}" data-tip="${esc(interpTitle(c.it) + (c.mode ? ' · ' + c.mode + ' mode' : '') + (evTip ? '\n' + evTip : ''))}">` +
      (evs.length ? `<span class="ev ${evs.length === 1 ? evs[0].kind : ''}" aria-label="${esc(evTip)}">!</span>` : '') +
      `<span class="vt">${esc(c.it.edition + modeTag)}</span></th>`;
  });
  h1 += '<th class="sum" rowspan="3">Passed</th></tr>'; h2 += '</tr>'; h3 += '</tr>';
  // rows: interpreter status row first, then tests
  let rows = '';
  rows += `<tr class="grp"><td class="rowhead">interpreter</td>` + cols.map((c, k) => {
    const evs = eventsByInterp.get(c.i) || [];
    const ok = c.it.ntests > 0 && !evs.length;
    const worst = evs.length ? (evs.every(e => e.kind === 'missing') ? 'error' : evs.every(e => e.kind === 'exit') ? 'skipped' : 'interrupted') : (c.it.ntests ? 'passed' : 'notrun');
    const tip = evs.length ? evs.map(e => `${EVENT_LABEL[e.kind] || e.kind}: ${e.msg}`).join('\n') : (ok ? `ran ${c.it.ntests} test runs in ${fmtSecs(c.it.time)}` : 'no tests ran');
    return `<td class="c" data-col="${k}"><button class="cell ${worst}" data-kind="interp" data-col="${k}" data-tip="${esc(interpTitle(c.it) + '\n' + tip)}" aria-label="${esc(tip)}">${worst === 'passed' ? '✓' : worst === 'notrun' ? '–' : '!'}</button></td>`;
  }).join('') + `<td class="sum"></td></tr>`;
  D.tests.forEach((t, ti) => {
    let n = {passed: 0, failed: 0, error: 0, skipped: 0, interrupted: 0, notrun: 0};
    const cells = cols.map((c, k) => {
      const r = cellStatus(ti, c); n[r.s]++;
      const isNew = hasPrev && r.c && r.c.s !== 'passed' && r.c.age === 1;
      return `<td class="c" data-col="${k}"><button class="cell ${r.s}${isNew ? ' new' : ''}" data-t="${ti}" data-col="${k}" data-s="${r.s}" aria-label="${esc(t + ' · ' + c.id + ': ' + STATUS_LABEL[r.s])}">${GLYPH[r.s]}</button></td>`;
    }).join('');
    const ran = cols.length - n.notrun;
    const bad = n.failed + n.error + n.interrupted + n.skipped;
    rows += `<tr data-t="${ti}" data-bad="${bad}"><td class="rowhead"><span class="mono">${esc(t)}</span></td>${cells}` +
      `<td class="sum">${n.passed}/${ran}<span class="bar" aria-hidden="true">${bar(n, ran)}</span></td></tr>`;
  });
  el.innerHTML = `<table class="matrix"><thead>${h1}${h2}${h3}</thead><tbody>${rows}</tbody></table>`;
  applyFilters();
}
function groupBy(arr, f) { const m = new Map(); arr.forEach(x => { const k = f(x); if (!m.has(k)) m.set(k, []); m.get(k).push(x); }); return m; }

function applyFilters() {
  const table = $('#matrix table'); if (!table) return;
  const q = state.q.trim().toLowerCase();
  // columns
  const colVisible = cols.map(c => {
    if (!state.platforms.has(c.it.platform)) return false;
    if (D.modes.length > 1 && c.mode && !state.modes.has(c.mode)) return false;
    if (state.onlyFailingCols) {
      const bad = D.tests.some((t, ti) => { const s = cellStatus(ti, c).s; return s !== 'passed' && s !== 'notrun'; }) || (eventsByInterp.get(c.i) || []).length;
      if (!bad) return false;
    }
    return true;
  });
  table.querySelectorAll('[data-col]').forEach(el => el.classList.toggle('hidecol', !colVisible[+el.dataset.col]));
  // header colspans follow the visible columns
  for (const tr of table.tHead.rows) {
    if (tr.rowIndex > 1) break;
    let k = 0;
    for (const th of tr.cells) {
      if (th.classList.contains('rowhead') || th.classList.contains('sum')) continue;
      const span = +th.getAttribute('colspan') || 1; const orig = +(th.dataset.span || span); th.dataset.span = orig;
      const vis = colVisible.slice(k, k + orig).filter(Boolean).length; k += orig;
      th.setAttribute('colspan', Math.max(vis, 1)); th.classList.toggle('hidecol', vis === 0);
    }
  }
  // rows
  D.tests.forEach((t, ti) => {
    const tr = table.querySelector(`tr[data-t="${ti}"]`);
    let show = true;
    if (state.onlyFailingRows || state.onlyNew || q) {
      show = false;
      cols.forEach((c, k) => {
        if (show || !colVisible[k]) return;
        const r = cellStatus(ti, c);
        const bad = r.s !== 'passed' && r.s !== 'notrun';
        if (state.onlyFailingRows && !bad) return;
        if (state.onlyNew && !(r.c && bad && r.c.age === 1)) return;
        if (q && !(t.toLowerCase().includes(q) || (r.c && ((r.c.msg || '') + ' ' + (r.c.d || '')).toLowerCase().includes(q)))) return;
        show = true;
      });
      if (q && !state.onlyFailingRows && !state.onlyNew && t.toLowerCase().includes(q)) show = true;
    }
    tr.classList.toggle('hidden', !show);
    // dim the cells that do not match the search
    if (q) tr.querySelectorAll('button.cell[data-t]').forEach(b => {
      const r = cellStatus(ti, cols[+b.dataset.col]);
      b.classList.toggle('dim', !(t.toLowerCase().includes(q) || (r.c && ((r.c.msg || '') + ' ' + (r.c.d || '')).toLowerCase().includes(q))));
    }); else tr.querySelectorAll('button.cell.dim').forEach(b => b.classList.remove('dim'));
  });
  const shown = D.tests.filter((t, ti) => !table.querySelector(`tr[data-t="${ti}"]`).classList.contains('hidden')).length;
  $('#mcount').textContent = `${shown} of ${D.tests.length} tests · ${colVisible.filter(Boolean).length} of ${cols.length} interpreter runs`;
}

function renderFilters() {
  const f = $('#filters');
  let html = `<input type="search" id="q" placeholder="Search test names, messages and stacks" aria-label="Search">`;
  html += `<label><input type="checkbox" id="frows"> only tests with failures</label>`;
  html += `<label><input type="checkbox" id="fcols"> only interpreters with failures</label>`;
  if (hasPrev) html += `<label><input type="checkbox" id="fnew"> only new failures</label>`;
  html += `<span class="chips" id="fplat">` + D.platforms.map(p => `<span class="chip" data-p="${p.id}" role="button" tabindex="0" aria-pressed="true">${esc(p.label)}</span>`).join('') + `</span>`;
  if (D.modes.length > 1) html += `<span class="chips" id="fmode">` + D.modes.map(m => `<span class="chip" data-m="${m}" role="button" tabindex="0" aria-pressed="true">${esc(m)}</span>`).join('') + `</span>`;
  html += `<span id="mcount" style="margin-left:auto"></span>`;
  f.innerHTML = html;
  $('#q').addEventListener('input', e => { state.q = e.target.value; applyFilters(); });
  $('#frows').addEventListener('change', e => { state.onlyFailingRows = e.target.checked; applyFilters(); });
  $('#fcols').addEventListener('change', e => { state.onlyFailingCols = e.target.checked; applyFilters(); });
  if ($('#fnew')) $('#fnew').addEventListener('change', e => { state.onlyNew = e.target.checked; applyFilters(); });
  const toggle = (chip, set, key) => { const v = chip.dataset[key]; if (set.has(v)) set.delete(v); else set.add(v);
    chip.classList.toggle('off', !set.has(v)); chip.setAttribute('aria-pressed', set.has(v)); applyFilters(); };
  f.querySelectorAll('#fplat .chip').forEach(ch => { ch.addEventListener('click', () => toggle(ch, state.platforms, 'p'));
    ch.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(ch, state.platforms, 'p'); } }); });
  f.querySelectorAll('#fmode .chip').forEach(ch => { ch.addEventListener('click', () => toggle(ch, state.modes, 'm'));
    ch.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(ch, state.modes, 'm'); } }); });
}

// ---- failures grouped by message
function stackBlock(details) {   // the stack (or log tail) of a group of occurrences: the first one, and how many others differ from it
  const ds = [...new Set(details.filter(Boolean))];
  if (!ds.length) return '';
  return `<pre class="stack">${esc(ds[0])}</pre>` + (ds.length > 1 ? `<div class="note">${ds.length - 1} other variant${ds.length > 2 ? 's' : ''} of this stack among the occurrences - click a cell in the matrix to see its own</div>` : '');
}
function normalise(msg) {
  return (msg || '').replace(/linktest-\d+/g, 'linktest-N').replace(/[A-Za-z]:\\[^ ⍝]*|\/[^ ⍝]*linktest-N[^ ⍝]*/g, p => p.replace(/^.*linktest-N/, '…/linktest-N'))
    .replace(/\d+(\.\d+)?s\b/g, 'Ns').replace(/exit code \d+/g, 'exit code N').replace(/\s+/g, ' ').trim();
}
function renderGroups() {
  const groups = new Map();
  D.cases.filter(c => c.s !== 'passed').forEach(c => {
    const k = c.s + '|' + normalise(c.msg);
    if (!groups.has(k)) groups.set(k, {s: c.s, msg: c.msg, tests: new Set(), interps: new Set(), items: []});
    const g = groups.get(k); g.tests.add(D.tests[c.t] + (c.m ? ' (' + c.m + ')' : '')); g.interps.add(c.i); g.items.push(c);
  });
  D.events.forEach(e => {
    const k = 'event|' + e.kind + '|' + normalise(e.msg);
    if (!groups.has(k)) groups.set(k, {s: e.kind, msg: e.msg, tests: new Set(), interps: new Set(), items: [], event: true});
    const g = groups.get(k); g.tests.add(e.name); if (e.interp != null) g.interps.add(e.interp); else g.tests.add(e.group); g.items.push(e);
  });
  const list = [...groups.values()].sort((a, b) => b.items.length - a.items.length);
  const el = $('#groups');
  $('#gcount').textContent = list.length ? `${list.length} distinct message${list.length > 1 ? 's' : ''} · ${list.reduce((n, g) => n + g.items.length, 0)} occurrences` : '';
  if (!list.length) { el.innerHTML = '<div class="card empty">Nothing failed.</div>'; return; }
  el.innerHTML = list.map((g, gi) => {
    const interps = [...g.interps].map(i => D.interps[i]).sort((a, b) => D.interps.indexOf(a) - D.interps.indexOf(b));
    const platforms = [...new Set(interps.map(i => i.platform_label))];
    const where = g.event ? (interps.length ? `${interps.length} interpreter${interps.length > 1 ? 's' : ''}` : [...g.tests].join(', '))
      : `${g.tests.size} test${g.tests.size > 1 ? 's' : ''} · ${interps.length} interpreter${interps.length > 1 ? 's' : ''}`;
    const isNew = hasPrev && !g.event && g.items.every(c => c.age === 1);
    return `<details class="g" id="g${gi}"><summary><span class="n">${g.items.length}</span><span><span class="tag ${g.s}">${esc(g.event ? EVENT_LABEL[g.s] || g.s : STATUS_LABEL[g.s])}</span>${isNew ? ' <span class="tag" style="background:var(--accent)">new</span>' : ''}</span>` +
      `<span class="msg mono">${esc(g.msg || '(no message)')}</span><span class="where">${esc(where)}${platforms.length ? ' · ' + esc(platforms.join(', ')) : ''}</span></summary>` +
      `<div class="body"><div class="full mono">${esc(g.msg || '(no message)')}</div>` + stackBlock(g.items.map(x => g.event ? x.detail : x.d)) +
      (g.event ? '' : `<div><b>Tests:</b></div><div class="pills">${[...g.tests].sort().map(t => `<span class="pill mono">${esc(t)}</span>`).join('')}</div>`) +
      (interps.length ? `<div style="margin-top:8px"><b>Interpreters:</b></div><div class="pills">${interps.map(i => `<span class="pill" title="${esc(interpTitle(i))}">${i.log ? `<a href="${esc(i.log)}">${esc(i.id)}</a>` : esc(i.id)}</span>`).join('')}</div>` : '') +
      (g.event ? '' : `<div style="margin-top:8px"><b>Where:</b></div><div class="pills">${g.items.slice(0, 60).map(c => { const i = D.interps[c.i]; const label = `${D.tests[c.t]}${c.m ? ' (' + c.m + ')' : ''} @ ${i.id}`;
          return `<span class="pill mono">${c.url ? `<a href="${esc(c.url)}">${esc(label)}</a>` : esc(label)}</span>`; }).join('')}${g.items.length > 60 ? `<span class="pill">… ${g.items.length - 60} more</span>` : ''}</div>`) +
      `</div></details>`;
  }).join('');
}

// ---- interpreters table
function renderInterps() {
  const rows = [];
  D.interps.forEach((it, i) => {
    const evs = eventsByInterp.get(i) || [];
    const n = it.counts; const total = it.ntests;
    const bad = n.failed + n.error + (n.skipped || 0) + evs.length;
    const modes = it.modes.filter(Boolean).join(', ');
    const status = evs.length ? evs.map(e => `<span class="tag ${e.kind}" title="${esc(e.msg)}">${esc(EVENT_LABEL[e.kind] || e.kind)}</span>`).join(' ')
      : total ? (bad ? `<span class="tag failed">${n.failed + n.error} failing</span>` : `<span class="tag ok">all passed</span>`) : `<span class="tag missing">no results</span>`;
    const links = [];
    if (it.url) links.push(`<a href="${esc(it.url)}">Jenkins</a>`);
    if (it.log) links.push(`<a href="${esc(it.log)}">log</a>`);
    it.cores.forEach((c, k) => links.push(`<a href="${esc(c)}">aplcore${it.cores.length > 1 ? ' ' + (k + 1) : ''}</a>`));
    rows.push(`<tr class="${bad ? 'bad' : ''}"><td><span class="mono">${esc(it.id)}</span></td><td>${esc(it.platform_label)}</td><td>${esc(it.version)}</td><td>${esc(edLabel(it.edition))}</td>` +
      `<td>${esc(modes)}</td><td>${status}</td>` +
      `<td class="num">${n.passed}</td><td class="num">${n.failed}</td><td class="num">${n.error}</td>` +
      `<td><span class="bar" aria-hidden="true">${bar(n, total)}</span></td>` +
      `<td class="num">${total ? fmtSecs(it.time) : ''}</td><td class="num">${it.attempts > 1 ? it.attempts : ''}</td><td>${links.join(' · ')}</td></tr>`);
  });
  // platform/version cells that could not run at all
  for (const [k, evs] of eventsByGroup) {
    const e = evs[0];
    rows.push(`<tr class="bad"><td><span class="mono">${esc(e.label)}</span></td><td>${esc((D.platforms.find(p => p.id === e.platform) || {}).label || e.platform)}</td><td>${esc(e.version)}</td><td colspan="2"></td>` +
      `<td>${evs.map(x => `<span class="tag ${x.kind}" title="${esc(x.msg)}">${esc(EVENT_LABEL[x.kind] || x.kind)}</span>`).join(' ')} <span style="color:var(--ink2)">${esc(e.msg)}</span></td><td colspan="6"></td><td>${e.url ? `<a href="${esc(e.url)}">Jenkins</a>` : ''}</td></tr>`);
  }
  $('#interps').innerHTML = `<table class="plain"><thead><tr><th>Interpreter</th><th>Platform</th><th>Dyalog</th><th>Edition</th><th>Mode</th><th>Status</th>` +
    `<th class="num">Passed</th><th class="num">Failed</th><th class="num">Errors</th><th></th><th class="num">Time</th><th class="num">Starts</th><th>Links</th></tr></thead><tbody>${rows.join('')}</tbody></table>`;
}

// ---- tooltip & detail panel
const tip = $('#tip');
let tipTarget = null, tipTimer = null;
function positionTip(anchor) {
  const a = anchor.getBoundingClientRect(), r = tip.getBoundingClientRect();
  let left = a.left + a.width / 2 - r.width / 2, top = a.bottom + 8;
  if (top + r.height > window.innerHeight - 8) top = a.top - r.height - 8;   // above the cell when there is no room below
  if (top < 8) top = 8;
  left = Math.max(8, Math.min(left, window.innerWidth - r.width - 8));
  tip.style.left = left + 'px'; tip.style.top = top + 'px';
}
function showTipFor(target) {
  if (target === tipTarget) return;
  clearTimeout(tipTimer); tipTimer = null;
  tipTarget = target;
  const btn = target.matches('td.c') ? target.querySelector('button.cell') : target;
  tip.innerHTML = btn && btn.matches('button.cell') && !btn.dataset.tip ? cellTip(btn) : `<div>${esc(target.dataset.tip || (btn && btn.dataset.tip) || '').replace(/\n/g, '<br>')}</div>`;
  tip.style.display = 'block';
  positionTip(btn || target);
  highlight(btn && btn.dataset.col != null ? +btn.dataset.col : (target.dataset.col != null ? +target.dataset.col : null));
}
function hideTip(now) {
  clearTimeout(tipTimer);
  const doIt = () => { tip.style.display = 'none'; tipTarget = null; highlight(null); };
  if (now) doIt(); else tipTimer = setTimeout(doIt, 80);   // a short grace period, so crossing the gap between two cells does not blink
}
let hlCol = null;
function highlight(k) {   // the hovered column, so that the header and the cell can be matched up in a wide matrix
  if (k === hlCol) return;
  const table = $('#matrix table'); if (!table) return;
  if (hlCol != null) table.querySelectorAll(`[data-col="${hlCol}"]`).forEach(el => el.classList.remove('hl'));
  hlCol = k;
  if (k != null) table.querySelectorAll(`[data-col="${k}"]`).forEach(el => el.classList.add('hl'));
}
function cellTip(btn) {
  const ti = +btn.dataset.t, col = cols[+btn.dataset.col], r = cellStatus(ti, col);
  let s = `<b>${esc(D.tests[ti])}${col.mode ? ' (' + esc(col.mode) + ')' : ''}</b><br><span class="m">${esc(col.it.id)} · ${esc(interpTitle(col.it))}</span><br>`;
  s += `<span class="tag ${r.s}">${STATUS_LABEL[r.s]}</span>`;
  if (r.c) { if (r.c.time != null) s += ` <span class="m">${fmtSecs(r.c.time)}</span>`;
    if (r.c.attempt > 1) s += ` <span class="m">· interpreter start ${r.c.attempt}</span>`;
    if (r.c.s !== 'passed' && r.c.age) s += ` <span class="m">· failing for ${r.c.age} build${r.c.age > 1 ? 's' : ''}${r.c.since ? ' (since #' + r.c.since + ')' : ''}</span>`;
    if (r.c.msg) s += `<div class="msg">${esc(r.c.msg)}</div>`; }
  if (r.e) s += `<div class="msg">${esc(r.e.msg)}</div>`;
  if (r.s === 'notrun') s += `<div class="m">no result for this test in this interpreter</div>`;
  s += `<div class="m" style="margin-top:4px">click to pin</div>`;
  return s;
}
const HOVERABLE = 'td.c, button.cell, [data-tip]';
document.addEventListener('mouseover', e => {
  const t = e.target.closest(HOVERABLE);
  if (t) showTipFor(t.matches('button.cell') && t.parentElement.matches('td.c') ? t.parentElement : t); else if (tipTarget) hideTip(false);
});
document.addEventListener('mouseleave', () => hideTip(true));
$('#matrix').addEventListener('scroll', () => hideTip(true), {passive: true});
window.addEventListener('scroll', () => hideTip(true), {passive: true});
document.addEventListener('focusin', e => { const t = e.target.closest('button.cell'); if (t) showTipFor(t.parentElement.matches('td.c') ? t.parentElement : t); });
document.addEventListener('focusout', () => hideTip(false));
document.addEventListener('click', e => {
  const b = e.target.closest('button.cell'); if (!b) return;
  hideTip(true);
  const col = cols[+b.dataset.col];
  const d = $('#detail');
  if (b.dataset.kind === 'interp') {
    const evs = eventsByInterp.get(col.i) || [];
    d.innerHTML = `<div class="hd"><h3>${esc(col.it.id)}</h3><button class="x" aria-label="Close">×</button></div><div style="color:var(--ink2)">${esc(interpTitle(col.it))}</div>` +
      `<div class="kv"><div>Test runs</div><div>${col.it.ntests} (${col.it.counts.passed} passed, ${col.it.counts.failed} failed, ${col.it.counts.error} errors) in ${fmtSecs(col.it.time)}</div>` +
      `<div>Modes</div><div>${esc(col.it.modes.filter(Boolean).join(', ') || '–')}</div><div>Starts</div><div>${col.it.attempts || '–'}</div>` +
      `<div>Links</div><div>${[col.it.url && `<a href="${esc(col.it.url)}">Jenkins suite</a>`, col.it.log && `<a href="${esc(col.it.log)}">log</a>`, ...col.it.cores.map(c => `<a href="${esc(c)}">aplcore</a>`)].filter(Boolean).join(' · ') || '–'}</div></div>` +
      evs.map(ev => `<div class="msg"><span class="tag ${ev.kind}">${esc(EVENT_LABEL[ev.kind] || ev.kind)}</span> ${esc(ev.msg)}</div>` + (ev.detail ? `<pre class="stack">${esc(ev.detail)}</pre>` : '')).join('');
  } else {
    const ti = +b.dataset.t, r = cellStatus(ti, col), c = r.c;
    d.innerHTML = `<div class="hd"><h3><span class="mono">${esc(D.tests[ti])}${col.mode ? ' (' + esc(col.mode) + ')' : ''}</span></h3><button class="x" aria-label="Close">×</button></div>` +
      `<div><span class="tag ${r.s}">${STATUS_LABEL[r.s]}</span> <span style="color:var(--ink2)">on ${esc(col.it.id)} · ${esc(interpTitle(col.it))}</span></div>` +
      `<div class="kv">` + (c ? `<div>Duration</div><div>${fmtSecs(c.time)}</div>` + (c.attempt ? `<div>Interpreter start</div><div>${c.attempt}${col.it.attempts > 1 ? ' of ' + col.it.attempts : ''}</div>` : '') +
        (c.s !== 'passed' && c.age != null ? `<div>Failing for</div><div>${c.age} build${c.age > 1 ? 's' : ''}${c.since ? ' (since #' + c.since + ')' : ''}</div>` : '') : '') +
      `<div>Links</div><div>${[c && c.url && `<a href="${esc(c.url)}">Jenkins test page</a>`, col.it.log && `<a href="${esc(col.it.log)}">interpreter log</a>`, ...col.it.cores.map(x => `<a href="${esc(x)}">aplcore</a>`)].filter(Boolean).join(' · ') || '–'}</div></div>` +
      ((c && c.msg) || (r.e && r.e.msg) ? `<div class="msg mono">${esc((c && c.msg) || r.e.msg)}</div>` : '') +
      ((c && c.d) || (r.e && r.e.detail) ? `<pre class="stack">${esc((c && c.d) || r.e.detail)}</pre>` : '') +
      (r.s === 'notrun' ? `<div class="msg">No result for this test in this interpreter run${(eventsByInterp.get(col.i) || []).length ? ': ' + esc(eventsByInterp.get(col.i).map(e => e.msg).join('; ')) : '.'}</div>` : '');
  }
  d.classList.add('show');
  $('.x', d).addEventListener('click', () => d.classList.remove('show'));
});
document.addEventListener('keydown', e => { if (e.key === 'Escape') { $('#detail').classList.remove('show'); hideTip(true); } });

// ---- theme toggle
$('#theme').addEventListener('click', () => {
  const r = document.documentElement; const dark = r.dataset.theme ? r.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  r.dataset.theme = dark ? 'light' : 'dark';
  try { localStorage.setItem('linktest-theme', r.dataset.theme); } catch (e) {}
});
try { const t = localStorage.getItem('linktest-theme'); if (t) document.documentElement.dataset.theme = t; } catch (e) {}

renderFilters(); renderMatrix(); renderGroups(); renderInterps();
"""


def render_html(model):
    meta = model['meta']
    e = html.escape
    title = 'Link tests · %s' % (('#%s' % meta['number']) if meta['number'] else os.path.basename(meta['name'].rstrip('/')) or 'local')
    heading = e(meta['name']) if meta['source'] == 'jenkins' else 'Link tests · ' + e(os.path.basename(meta['name'].rstrip('/')) or meta['name'])
    result = meta['result'] or ('local run')
    badge_class = meta['result'] or 'UNKNOWN'

    bits = []
    if meta['timestamp']:
        when = datetime.datetime.fromtimestamp(meta['timestamp'] / 1000).astimezone()
        bits.append('<span><b>%s</b>%s</span>' % ('Started ' if meta['source'] == 'jenkins' else 'Reports written ', e(when.strftime('%a %d %b %Y %H:%M %Z'))))
    if meta['duration']:
        secs = meta['duration'] // 1000
        bits.append('<span><b>took</b> %s</span>' % ('%d min' % (secs // 60) if secs < 5400 else '%.1f h' % (secs / 3600)))
    if meta['branch'] or meta['sha']:
        sha = meta['sha'] or ''
        repo = (meta['remote'] or '').replace('.git', '')
        commit = '<a href="%s/commit/%s">%s</a>' % (e(repo), e(sha), e(sha[:10])) if repo and sha else e(sha[:10])
        bits.append('<span><b>%s</b> %s</span>' % (e(meta['branch'] or 'commit'), commit))
    if meta['cause']:
        bits.append('<span>%s</span>' % e(meta['cause']))
    tests_param = (meta.get('params') or {}).get('TESTS')
    if tests_param and tests_param != 'all':
        bits.append('<span><b>TESTS</b> <code>%s</code></span>' % e(str(tests_param)))
    off = [k[4:].lower() for k, v in (meta.get('params') or {}).items() if k.startswith('RUN_') and v is False]
    if off:
        bits.append('<span><b>not run</b> %s</span>' % e(', '.join(off)))

    links = ['<button class="btn" id="theme" title="Toggle light/dark">◐</button>']
    if meta['source'] == 'jenkins':
        u = meta['url']
        links = ['<a class="btn" href="%s">Build</a>' % e(u), '<a class="btn" href="%stestReport/">Test result</a>' % e(u),
                 '<a class="btn" href="%sconsole">Console</a>' % e(u), '<a class="btn" href="%sartifact/results/">Artifacts</a>' % e(u)] + links

    data = json.dumps(model, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(title)s</title>
<style>%(css)s</style>
</head>
<body>
<div class="wrap">
<header>
  <div>
    <h1>%(heading)s <span class="badge %(badge_class)s">%(result)s</span></h1>
    <div class="meta">%(meta)s</div>
  </div>
  <div class="links">%(links)s</div>
</header>
<section class="kpis" id="kpis"></section>
<section class="card">
  <h2>Test matrix <small id="mcount"></small></h2>
  <div class="filters" id="filters"></div>
  <div class="scroller" id="matrix"></div>
  <div class="legend">
    <span><span class="sw st-passed">✓</span>passed</span>
    <span><span class="sw st-failed">✕</span>failed assertion</span>
    <span><span class="sw st-error" style="color:#0b0b0b">!</span>error</span>
    <span><span class="sw st-failed">‼</span>interpreter died in this test</span>
    <span><span class="sw st-notrun" style="color:var(--notrun-ink)">–</span>not run</span>
    <span style="margin-left:auto">Columns are interpreters (bits + Classic/Unicode%(modes)s); hover a cell for the message, click to pin it.</span>
  </div>
</section>
<section>
  <h2>Failures by message <small id="gcount"></small></h2>
  <div class="grp-list" id="groups"></div>
</section>
<section class="card">
  <h2>Interpreters</h2>
  <div class="tablewrap" id="interps"></div>
</section>
<footer>Generated %(generated)s by CI/testreport.py from %(source)s.</footer>
</div>
<div id="tip" role="tooltip"></div>
<div id="detail" class="card" role="dialog" aria-label="Details"></div>
<script id="data" type="application/json">%(data)s</script>
<script>%(js)s</script>
</body>
</html>
''' % {
        'title': e(title), 'css': CSS, 'js': JS, 'heading': heading, 'badge_class': e(badge_class), 'result': e(result),
        'meta': ' '.join(bits), 'links': ' '.join(links), 'data': data,
        'modes': ', W = watcher, C = crawler' if len(model['modes']) > 1 else '',
        'generated': e(datetime.datetime.now().strftime('%Y-%m-%d %H:%M')),
        'source': ('<a href="%s">%s</a>' % (e(meta['url']), e(meta['url']))) if meta['source'] == 'jenkins' else e(meta['name']),
    }


# ----------------------------------------------------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0], formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog='\n'.join(__doc__.split('\n\n')[1:]))
    ap.add_argument('source', help='Jenkins build URL (the build page, or its testReport/ page), or a results/ folder')
    ap.add_argument('-o', '--output', help='HTML file to write (default: testreport.html, or <folder>/testreport.html for a local folder)')
    ap.add_argument('--open', action='store_true', help='open the report in the browser when done')
    ap.add_argument('-q', '--quiet', action='store_true', help='no progress messages')
    args = ap.parse_args()

    if re.match(r'^https?://', args.source):
        meta, suites, history = load_jenkins(normalise_build_url(args.source), quiet=args.quiet)
        out = args.output or 'testreport.html'
    else:
        meta, suites, history = load_local(args.source)
        out = args.output or os.path.join(args.source, 'testreport.html')

    out = os.path.abspath(out)
    model = build_model(meta, suites, history, os.path.dirname(out))
    with open(out, 'w', encoding='utf-8') as f:
        f.write(render_html(model))

    n = {'passed': 0, 'failed': 0, 'error': 0, 'skipped': 0}
    for c in model['cases']:
        n[c['s']] = n.get(c['s'], 0) + 1
    if not args.quiet:
        print('%s: %d interpreters, %d test runs: %d passed, %d failed, %d errors; %d interpreter problems' % (
            out, len(model['interps']), len(model['cases']), n['passed'], n['failed'], n['error'], len(model['events'])), file=sys.stderr)
    if args.open:
        webbrowser.open('file://' + urllib.request.pathname2url(out))


if __name__ == '__main__':
    main()
