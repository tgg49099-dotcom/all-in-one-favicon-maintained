# tests/ - the compatibility harness

This directory holds the harness used to measure the breakage on the official
code and to prove the patched code is clean, plus the **raw output of every
run** (`results/`).

Nothing here is a mock: the tests run against **real WordPress installations**
and real PHP binaries.

## What is used

| | |
|---|---|
| WordPress | 6.8.12 and 7.1.4 (real releases, own SQLite database each) |
| PHP | 8.3.29 and 8.5.8 (real binaries) |
| Plugin | All In One Favicon 4.8, official ZIP from wordpress.org |
| Variants | `original` = untouched official code, `fixed` = this repository's patched code |

The WordPress installations are **not** committed: they are downloaded and set up
by `setup-env.sh` (it needs network access and a few hundred MB), and the
official plugin code is downloaded and md5-checked by `fetch-original.sh`.

## The 8 cases

The matrix is `{original, fixed}` x `{wp-6.8.12, wp-7.1.4}` x `{8.3.29, 8.5.8}` =
**8 cases, played sequentially**.

They are deliberately **not** run in parallel: two WordPress instances sharing
the same sandbox produce false results (a suite of this kind is not
parallelisable - one instance reports a red that is not there).

Each case runs the same 8 tests against the plugin's own workflows:

| test | what it does |
|---|---|
| T1 | activates the plugin in a real WordPress |
| T2 | loads the public front page |
| T3 | loads the administration dashboard |
| T4 | loads the plugin's own settings screen (`admin.php?page=all-in-one-favicon`) |
| T5 | **saves** the settings through the plugin's real form (`admin-post.php`, form id `aio-favicon-settings-update`) and checks that the option really contains the submitted value |
| T6 | **deletes** the settings through the plugin's real form (`admin-post.php`, form id `delete_settings`) |
| T7 | loads the plugin's other screens (other tools, AppSumo page, general settings, media library) |
| T8 | checks that the favicon `<link rel="icon">` tags are rendered in the public front |

A test is **RED** when the plugin wrote any PHP diagnostic into
`wp-content/debug.log`, or when the expected result is missing.

## Files

| file | role |
|---|---|
| `lib.sh` | shared configuration: slug, ports, PHP paths, paths of the two WordPress installations |
| `setup-env.sh` | downloads and prepares the two WordPress installations (`bash setup-env.sh all`) |
| `fetch-original.sh` | downloads the **official** plugin ZIP and checks its md5 (`f4d3146d5aca7def9fd1694a831084cb`) |
| `apply-compat-patch.py` | applies the compatibility patches to the official code (the script used to build this fork) |
| `run-case.sh` | runs the 8 tests of one case and writes `resultats.txt` |
| `form-post.py` | posts the plugin's real settings form with the cookies and the nonce of a logged-in administrator |
| `run-matrix.sh` | runs the 8 cases, one after the other, and writes the summary |
| `results/` | the raw output of the runs, exactly as it was produced |
| `results/contre-preuve-rouge.txt` | the counter-proof: the same suites, run against the untouched official code, with the raw PHP diagnostics |

## Configuration

Everything is set through environment variables, so the harness can run from a
fresh clone:

| variable | default |
|---|---|
| `AIOF_BASE` | the root of this repository |
| `AIOF_WPCLI` | `tools/wp-cli.phar` |
| `AIOF_PHP_83` | `php8.3` from the `PATH` |
| `AIOF_PHP_85` | `php8.5` from the `PATH` |
| `WPE_SQLITE_SRC` | `tools/sqlite-database-integration` (the SQLite drop-in) |

## Reading the results

`results/<variante>-<wp>-<php>/resultats.txt` holds one line per test:

```
VERT | T1 activation | aucune erreur fatale, 0 diagnostic
VERT | T2 front public | HTTP 200, 0 diagnostic
...
```

`results/<variante>-<wp>-<php>/debug.log.plugin-only.txt` holds the PHP
diagnostics **attributable to the plugin** (the lines of `wp-content/debug.log`
that come from the plugin's own files).

`results/<variante>-<wp>-<php>/console.txt` holds the full console output of the
case, and `results/matrice.txt` the summary of the 8 cases.

## Reproducing

```bash
bash fetch-original.sh      # the official code, md5-checked
bash setup-env.sh all       # the two WordPress installations
bash run-matrix.sh all      # the 8 cases, sequentially
```

The summary ends with the verdict of each case. Expected result:

* the 4 `original` cases are **RED** (the official code writes PHP 8 deprecations),
* the 4 `fixed` cases are **VERT** (no diagnostic at all).
