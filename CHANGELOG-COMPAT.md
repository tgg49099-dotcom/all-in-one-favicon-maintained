# CHANGELOG-COMPAT.md

Compatibility-only changes applied to **All In One Favicon 4.8** (original
release: 2023-08-08, `https://downloads.wordpress.org/plugin/all-in-one-favicon.4.8.zip`,
md5 `f4d3146d5aca7def9fd1694a831084cb`, 140576 bytes).

Rules that were applied to every line below:

* **no feature added, no feature removed**;
* **no option added, renamed or removed**;
* **no user-visible text changed** (not one string literal, not one label);
* every corrected expression evaluates to **exactly the value PHP 7.x produced**,
  so the behaviour of the plugin is unchanged;
* the byte content of every untouched file is preserved exactly.

Only **four** files were modified, out of the **71** files of the official ZIP
(21 of them are PHP):

| file | change | what |
|---|---|---|
| `all-in-one-favicon/all-in-one-favicon.php` | +13 lines after the class opening | declaration of 3 properties |
| `all-in-one-favicon/includes/aio-favicon-backend.php` | +19 lines after the class opening, 1 line changed (365), 1 line changed (346) | declaration of 9 properties, guarded read of a settings key, `create_function()` replaced by a closure |
| `all-in-one-favicon/includes/aio-favicon-frontend.php` | +13 lines after the class opening | declaration of 2 properties |
| `all-in-one-favicon/includes/favicon-render-helper.php` | +13 lines after the class opening | declaration of 2 properties |

Every other file of the official ZIP (`readme.txt`, `README.md`, `other_tools.php`,
`appsumo.php`, `appsumo-capture-form.php`, the six `includes/settings-page/*.php`,
the six `js/*.js`, the two `styles/*.css`, the `images/`, the `scripts/`, the
`localization/` `.po`/`.mo` files, `.gitignore`) is byte-for-byte identical to the
original.

Verification of that claim:

```
$ diff -rq original/all-in-one-favicon fixed/all-in-one-favicon
Files original/all-in-one-favicon/all-in-one-favicon.php and fixed/all-in-one-favicon/all-in-one-favicon.php differ
Files original/all-in-one-favicon/includes/aio-favicon-backend.php and fixed/all-in-one-favicon/includes/aio-favicon-backend.php differ
Files original/all-in-one-favicon/includes/aio-favicon-frontend.php and fixed/all-in-one-favicon/includes/aio-favicon-frontend.php differ
Files original/all-in-one-favicon/includes/favicon-render-helper.php and fixed/all-in-one-favicon/includes/favicon-render-helper.php differ
```

---

## How the breakage was measured

Before changing anything, the official 4.8 code was installed in **real**
WordPress installations (6.8.12 and 7.1.4, each with its own SQLite database)
and driven with PHP 8.3.29 and PHP 8.5.8, through the plugin's own workflows:
activation, the public front, the administration dashboard, the plugin's own
settings screen, saving the settings through the real form, deleting the settings
through the real form, the plugin's other screens, and the rendering of the favicon
tags in the public front. Every PHP diagnostic written to `wp-content/debug.log`
by the plugin was collected.

The result on the **untouched** official code, on PHP 8.3.29 and on PHP 8.5.8:

| | WordPress 6.8.12 | WordPress 7.1.4 |
|---|---|---|
| PHP 8.3.29 | **167 diagnostics** written by the plugin | **167 diagnostics** |
| PHP 8.5.8 | **167 diagnostics** | **167 diagnostics** |

The 167 lines break down as:

* **153** `Deprecated: Creation of dynamic property ...` (16 distinct properties),
* **7** `Warning: Undefined array key "frontendGIF"` (and the 6 other favicon types),
* **7** `Deprecated: str_replace(): Passing null to parameter #3`.

On the patched code the same 8 runs produce **0 diagnostic** (the four
`debug.log.plugin-only.txt` of the `fixed` cases are empty).

(the raw logs are in `tests/results/<case>/debug.log.plugin-only.txt`).

A complementary static pass was run on the untouched source:

* every PHP file was linted with **PHP 8.3.29** and **PHP 8.5.8**
  (`php -l`): **0 error**, so the breakage is a runtime one, not a syntax one;
* every function **removed in PHP 8** was searched for
  (`create_function`, `each`, `ereg`, `eregi`, `split`, `ereg_replace`,
  `mysql_*`, `money_format`, `get_magic_quotes_gpc`, `restore_include_filter`,
  `set_magic_quotes_runtime`, `preg_replace_e`): **exactly one hit**,
  `create_function()` in `includes/aio-favicon-backend.php` (see break #2);
* every read of a superglobal (`$_GET`, `$_POST`, `$_REQUEST`, `$_FILES`,
  `$_SERVER`, `$_COOKIE`) was listed and checked against an `isset()`/`empty()`
  guard. The unguarded-looking ones are either guarded on the same line by a
  short-circuit (`isset($_GET['page']) && $_GET['page'] == ...`), or are values
  the web server or the plugin's own form always provides
  (`$_SERVER['SERVER_NAME']`, `$_SERVER['SERVER_PORT']`, `$_SERVER['REQUEST_URI']`,
  `$_POST['_wp_http_referer']`, `$_POST[AIOFAVICON_SETTINGSNAME]`). **None of them
  fired in any of the 8 runs**, so none of them was changed.

---

## Break #1 - "Deprecated: Creation of dynamic property" on every request

**Measured**, on the official code, in `wp-content/debug.log`:

```
PHP Deprecated:  Creation of dynamic property AllInOneFavicon::$aioFaviconSettings is deprecated
PHP Deprecated:  Creation of dynamic property AllInOneFavicon::$aioFaviconFrontendMap is deprecated
PHP Deprecated:  Creation of dynamic property AllInOneFavicon::$aioFaviconBackendMap is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$aioFaviconSettings is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$aioFaviconDefaultSettings is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$donationLoader is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$faviconRenderHelper is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$faviconFrontendMap is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$faviconBackendMap is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$faviconMap is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$identifier is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconBackend::$translatedIdentifier is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconFrontend::$aioFaviconSettings is deprecated
PHP Deprecated:  Creation of dynamic property AioFaviconFrontend::$faviconRenderHelper is deprecated
PHP Deprecated:  Creation of dynamic property FaviconRenderHelper::$aioFaviconSettings is deprecated
PHP Deprecated:  Creation of dynamic property FaviconRenderHelper::$aioFaviconType is deprecated
```

16 distinct properties, 153 occurrences over the 8 tests of one case: this
deprecation fires on **every** request that loads the plugin - the public front,
the dashboard, the settings screen. PHP 8.2 deprecated the creation of an
undeclared property; PHP 8.3 and 8.5 still emit it.

**Why it happens**: the four classes of the plugin declare **no property at all**
(`grep -c "public \$" ` is 0 in each of them), and assign their members with
`$this->x = ...`.

**The fix**: declare the 16 properties that the code already creates, with their
existing names. Declaring a property that the code already creates changes
**nothing**: same name, same value, same order, same visibility to the rest of
the plugin (they were public all along - a dynamic property is public).

**Why this is behaviour-preserving**: a declared property that is never assigned
is `null`, exactly like an undefined array read; the plugin reads these members
only after assigning them, and `isset()` on a declared-but-null property behaves
like `isset()` on a dynamic property. No branch of the plugin tests the
*existence* of a property with `property_exists()` or `get_object_vars()`: see
the "Checked and found clean" section.

## Break #2 - `create_function()` (removed in PHP 8.0)

**Measured** by reading the code (the branch is not reachable through the current
user interface, see below): `includes/aio-favicon-backend.php` line 346.

```php
add_action('admin_notices', create_function('', "echo '$message';"));
```

`create_function()` was **deprecated in PHP 7.2 and removed in PHP 8.0**: calling
it on PHP 8.x is a **fatal error** ("Call to undefined function create_function()").

**The fix**: the same closure, written out:

```php
add_action('admin_notices', function () use ($message) { echo $message; });
```

**Why this is behaviour-preserving**: `create_function('', "echo '$message';")`
interpolates `$message` into the body of the generated function *at creation
time*; `function () use ($message)` captures the same value at the same moment.
Both echo the identical string. The generated function had no arguments and no
return value; the closure has neither.

**This branch is not reachable in the current interface** - and that is a fact
worth recording, because it was checked rather than assumed: the notice is only
registered when `strpos($_SERVER['REQUEST_URI'], 'all-in-one-favicon.php')` is
truthy, but the settings screen of the plugin is registered with
`add_menu_page(..., 'all-in-one-favicon', ...)`, whose URL is
`/wp-admin/admin.php?page=all-in-one-favicon` and therefore never contains
`all-in-one-favicon.php`. The branch is kept fixed anyway, because it is one
line, because it is a call to a function that no longer exists in the language,
and because a future menu change could make it reachable.

## Break #3 - "Undefined array key" + "str_replace(): Passing null" when deleting the settings

**Measured**, on the official code, in `wp-content/debug.log`, during the
"Delete Settings" step of the plugin's own settings screen:

```
PHP Warning:  Undefined array key "frontendGIF" in .../includes/aio-favicon-backend.php on line 365
PHP Deprecated:  str_replace(): Passing null to parameter #3 ($subject) of type array|string is deprecated in .../includes/aio-favicon-backend.php on line 368
```

(and the same for `frontendPNG`, `frontendApple`, `backendICO`, `backendGIF`,
`backendPNG`, `backendApple`).

**Why it happens**: `deleteFile()` reads one settings entry per favicon type:

```php
$url = $this->aioFaviconSettings[$faviconName];
```

The settings array only holds the favicon types the site actually uses, so the
read of the other types is an undefined array key. In PHP 8.0 that is a
**warning**; in PHP 8.1 passing the resulting `null` to `str_replace()` is a
**deprecation**.

This happens on **every** click on the plugin's "Delete Settings" button, on
every site that does not use all eight favicon types - that is, on every site.

**The fix**:

```php
$url = isset( $this->aioFaviconSettings[$faviconName] ) ? $this->aioFaviconSettings[$faviconName] : '';
```

**Why this is behaviour-preserving**: in PHP 7.x the very same read produced
`null` (with a notice), `str_replace(..., null)` returned `''`, and the
`if ($url != '')` branch below was therefore already skipped. The patched code
reaches `''` by another route and skips the same branch. The line that follows
(`$this->aioFaviconSettings[$faviconName] = '';`) is unchanged, so the settings
array ends up exactly as before.

---

## Checked and found clean (nothing was changed there)

* `php -l` on the 21 PHP files, with PHP 8.3.29 and PHP 8.5.8: **0 error**.
* Functions removed in PHP 8, other than `create_function()`: **0 occurrence**.
* `each()`, `ereg*()`, `split()`: **0 occurrence**.
* Hook signatures: every `add_action()` / `add_filter()` passes a callable of a
  correct shape; `add_filter( 'plugin_action_links_' . plugin_basename(__FILE__), 'aiof_filter_plugin_actions', 10, 2 )`
  matches the `function aiof_filter_plugin_actions($links, $file)` it points to.
* The `AIOFaviconDonationLoader` class already declares its two properties
  (`var $donationLoaderPluginName`, `var $donationLoaderPluginUrl`): it is the one
  class of the plugin that is already PHP 8.2-clean.
* No call to `property_exists()`, `get_object_vars()`, `get_mro()`, `__set()` or
  `__get()` anywhere in the plugin: declaring the properties of break #1 cannot
  change any branch of the code.

## Known issues we did NOT change

* **The directory-traversal reports.** In March 2023 two threads on the plugin's
  public support forum reported a directory-traversal weakness
  ("vulnerable to Directory Traversal - critical threat", 2023-03-03, and
  "CRITICAL > Security Threat | Plugin abandoned?", 2023-03-27); a third thread
  in January 2024 ("PHP 8.2 compatibility patch", 2024-01-20) reported the
  deprecations fixed here. None of them was answered by the author. A security
  question belongs to the author and is not a compatibility question, so **no
  line of the code concerned was changed**. It is also not our place to publish a
  security assessment of someone else's plugin.
* **The `tax_input`-style behaviour of the settings form** is the author's
  design and was left alone.
* **The plugin's own `readme.txt`** still says `Tested up to: 6.2` and
  `Requires at least: 2.8`: it is the author's file, and changing it would be a
  statement about the plugin's support, not a compatibility fix.

## How to reproduce

```bash
python3 apply-compat-patch.py <official-zip-extracted> <target>
bash run-matrix.sh all
```

The raw output of the 8 runs, and the red/green counter-proof, are in
`tests/results/`.
