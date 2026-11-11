All In One Favicon - compatibility fork by Tgg Labs (unofficial)

This repository is an UNOFFICIAL compatibility fork of "All In One Favicon" by
Arne Franken / Garrett Grimm ("techotronic" on WordPress.org,
https://profiles.wordpress.org/grimmdude/), original plugin page
https://wordpress.org/plugins/all-in-one-favicon/, original site
http://www.techotronic.de/plugins/all-in-one-favicon/.

The original plugin's licence and its copyright notice are kept unchanged; see
LICENSE. We are not the original author and we do not sell this plugin. The
commercial side of the plugin - its AppSumo offer, its donations box and its
support - remain the property of its author, and we would not touch the
commercial part.

What we changed: compatibility only (PHP 8.3/8.5, WordPress 6.8/7.1). No feature, no
option and no user-visible text was changed. The list of changes is in
CHANGELOG-COMPAT.md, with the tests we ran in tests/.

Why: the last public release is 4.8 (August 2023) and the plugin is marked as tested
up to WordPress 6.2, while the current WordPress release is 7.1.4, and on PHP 8.2 and
later every request writes "Deprecated: Creation of dynamic property" notices for the
plugin. If the original author prefers to maintain the plugin himself, this
repository and these patches are his to use.

---

## Who does what

| | |
|---|---|
| Original plugin, all features, all wording, copyright | **Arne Franken / Garrett Grimm ("techotronic")** - https://profiles.wordpress.org/grimmdude/ - http://www.techotronic.de/plugins/all-in-one-favicon/ |
| Commercial side of the plugin (AppSumo offer, donations, support) | **the original author** - http://www.techotronic.de/plugins/all-in-one-favicon/ - untouched by this fork |
| This repository: PHP 8 / WordPress 6.8-7.1 compatibility patches, test harness, packaging | **Tgg Labs** (https://github.com/tgg49099-dotcom) - unofficial, free, no paid tier |
| WordPress.org plugin directory, its slug `all-in-one-favicon`, its page, its reviews, its SVN | **unchanged, still the original author's** - this repository is not published there |

Nothing here is submitted to the WordPress.org plugin directory. The plugin slug
`all-in-one-favicon` on wordpress.org is untouched by us.

## Repository layout

```
all-in-one-favicon/      the plugin, patched for compatibility (All In One Favicon 4.8)
tests/                   the test harness we used, and the raw output of the runs
CHANGELOG-COMPAT.md      every change we made, file by file, with the reason
NOTICE                   authorship, attribution and licensing notice
LICENSE                  the GNU General Public License v2 (the plugin's own licence)
```

The `all-in-one-favicon/` directory is the plugin itself and can be zipped and
installed as a normal WordPress plugin (the main folder name must stay
`all-in-one-favicon`).

## What we tested

The plugin was exercised on **real WordPress installations** (not a mock), with the
plugin's own workflows: activation, the public front, the administration dashboard,
the plugin's own settings screen, saving the settings through the real form, deleting
the settings through the real form, the plugin's other screens, and the rendering of
the favicon tags in the public front.

| | WordPress 6.8.12 | WordPress 7.1.4 |
|---|---|---|
| PHP 8.3.29 | tested | tested |
| PHP 8.5.8 | tested | tested |

The harness lives in `tests/` and the raw output of every run is in
`tests/results/`. `tests/run-matrix.sh` runs the whole matrix; the cases are run
**sequentially** on purpose (WordPress test suites of this kind are not
parallelisable in the same sandbox).

The same suite is run twice: once against the untouched official 4.8 code
(`original`) and once against the patched code (`fixed`). On the official code the
suite reports PHP 8 deprecation notices; on the patched code it reports none.

## Known issues we did NOT change

`CHANGELOG-COMPAT.md` lists them in full. In short: the directory-traversal reports
raised on the plugin's support forum in March 2023 are a security question for the
author, not a compatibility question, so we left the code alone and documented it
instead. We prefer a fork that behaves exactly like the original over a fork that
"improves" it.

## Licence

This fork is distributed under the same licence as the original plugin: the plugin
header declares `License: GPL` and the source header refers to "the GNU General
Public License"; the official `readme.txt` carries no `License:` line at all, so the
exact version the author meant is not written down anywhere in the release. The full
text of the GNU General Public License version 2 is in `LICENSE`; see NOTICE for the
precise wording and for what the author may want to correct.
