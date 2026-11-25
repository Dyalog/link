# Testing Link

How to run Link's test suite, and how CI runs it. The user documentation is under `docs/`.

## Running the tests in a session

Start Dyalog with `DYALOGLINK` set to the root of this checkout, so that the session loads Link from it. Then:

```apl
⎕TSYNC ⎕SE.Link.RunTests&''                       ⍝ the basic tests
⎕TSYNC ⎕SE.Link.RunTests&'all'                    ⍝ everything, including the slow tests (test_threads, test_watcherror)
⎕TSYNC ⎕SE.Link.RunTests&'test_add' 'test_create' ⍝ the tests whose names contain any of these strings
```

- Run the tests in a thread (the `&`): Link's crawler needs thread 0.
- The session must have no links of its own, or the tests refuse to start.
- `RunTests` prints each failure and a summary line, and returns `1` if every test passed.
- For 18.2, also set `DYALOGSTARTUPSE` to `<checkout>/StartupSession:<checkout>/qse/StartupSession` (with `;` instead
  of `:` on Windows).

**Watcher modes.** Each test runs with the .NET file watcher if the interpreter has .NET, and with Link's crawler if
not. To run both, set `⎕SE.Link.Watcher.CRAWLER←1` first.

**Debugging.** To stop at an error instead of having it trapped and reported, set `⎕SE.Link.DEBUG←1` before the first
run, or `⎕SE.LinkTest.debug←1` for later runs. Link re-signals errors from its API functions, so to stop inside Link,
add `Debug:{debug:1}` to the configuration file the tests use (`⎕SE.Link.USERCONFIGFILE`).

**Settings.** The tests are imported into `⎕SE.LinkTest`, and stay there until you expunge it. Optional settings,
such as `⎕SE.LinkTest.DO_GUI_TESTS←1`, are listed in `Test/InitGlobals.aplf`.

## Running the tests like CI

`CI/runlinktests` runs the suite in every interpreter of one Dyalog version on the machine, each in a fresh process,
and writes logs and JUnit reports to `results/`:

```sh
WORKSPACE=$PWD bash CI/runlinktests linux_native 21.0 test_add   # interpreters installed under /opt/mdyalog
WORKSPACE=$PWD bash CI/runlinktests linux_public 21.0            # in Docker, in the public dyalog/dyalog image
WORKSPACE=$PWD bash CI/runlinktests linux 21.0                   # in Docker, in Dyalog's internal nightly images
WORKSPACE=$(cygpath -w "$PWD") bash CI/runlinktests win 21.0     # Windows, from Cygwin or Git Bash
```

- The third argument is `all` (the default) or test names separated by spaces.
- `CI/testmatrix` lists the interpreters (32/64-bit, Classic/Unicode) expected for each platform and version. An
  expected interpreter that is not installed is reported as an error.
- Exit code: `0` every test passed, `1` tests failed, `2` the tests could not run (interpreter missing, crash,
  hang, ...).
- Each interpreter gets 5 minutes (`LINKTEST_TIMEOUT`, in seconds) before it is killed as hung. An interpreter that
  crashes or hangs is restarted for the remaining tests.
- `python3 CI/testreport.py results/` turns the results into one HTML page, `results/testreport.html`. It also takes
  the URL of a Jenkins build.
- Each run gets its own temporary directory (`TMPDIR`; `TMP`/`TEMP` on Windows), so runs in different checkouts
  don't collide. Under Jenkins it's `/tmp/linkci-<checksum of workspace path>`, emptied at the start and kept
  afterwards; otherwise a new `/tmp/linkci-XXXXXX`, removed if every test passed.

## Writing tests

A test is a function `Test/test_<name>.aplf` that returns `1` when it passes. Check things with `assert`,
`assertError` and `assertMsg`:
- **failed:** an assertion does not hold.
- **error:** any other error.

Either way the run cleans up the test's links and folder and goes on with the next test. A test that does not apply
to the interpreter (e.g. `test_classic` on Unicode) returns `1`.

## Continuous integration

| | GitHub Actions | Jenkins |
|---|---|---|
| Runs | every push to every branch, and pull requests from forks | `master` nightly, pull requests from branches of this repository, and by hand |
| Platforms | Linux, Windows, macOS | Windows, macOS, Linux (x64 and ARM), Raspberry Pi, AIX |
| Interpreters | the latest release, 64-bit Unicode | every supported version, 32/64-bit, Classic and Unicode, and the version in development |
| Defined in | `.github/workflows/test.yml` | `Jenkinsfile` |

Jenkins runs on Dyalog's internal machines, so it never builds pull requests from forks: GitHub Actions tests them.

Both read `CI/testmatrix`, which says what runs where. To add a Dyalog version, add its lines there. When a version
is released, move the `linux_public`, `win_public` and `mac_public` lines on to it.

A Jenkins build is UNSTABLE when tests failed and FAILURE when they could not run. Its *Test Result* page lists the
failures, and `results/` is archived with it. A GitHub Actions run attaches `results/` to the run.
