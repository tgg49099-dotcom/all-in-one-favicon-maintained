#!/usr/bin/env bash
# =============================================================================
# run-case.sh - UN cas de test : (variante) x (WordPress) x (PHP)
#
#   usage : run-case.sh <original|fixed> <wp-7.1.4|wp-6.8.12> <8.3.29|8.5.8>
#
# Tests (le workflow propre au plugin All In One Favicon) :
#   T1  activation du plugin
#   T2  front : page publique du site
#   T3  tableau de bord de l'administration
#   T4  ecran de reglages du plugin (admin.php?page=all-in-one-favicon)
#   T5  enregistrement des reglages par le VRAI formulaire du plugin
#       (admin-post.php, action=aioFaviconUpdateSettings)  <-- CONTRE-EPREUVE ROUGE
#   T6  suppression des reglages par le VRAI formulaire du plugin
#       (admin-post.php, action=aioFaviconDeleteSettings)
#   T7  pages annexes du plugin (Other Tools + redirection AppSumo)
#   T8  rendu du favicon dans le <head> du front apres enregistrement
#
# Un test est ROUGE si le plugin ecrit AU MOINS UN diagnostic PHP dans
# wp-content/debug.log, ou si le resultat attendu n'est pas obtenu.
#
# Sortie : une ligne VERT/ROUGE par test + un verdict final.
# Code de sortie 0 = tout vert, 1 = au moins un test rouge.
# =============================================================================
set -uo pipefail
BASE=${AIOF_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
source "$BASE/tests/lib.sh"

VARIANT="$1"; ENVN="$2"; PHPV="$3"
ENVDIR="$BASE/env/$ENVN"
PORT=$(env_port "$ENVN")
LOGDIR="$BASE/logs/$VARIANT-$ENVN-$PHPV"
mkdir -p "$LOGDIR"

PASS=0; FAIL=0
declare -a RESULTS=()

say()  { printf '%s\n' "$*"; }
res()  { # res <etat> <nom> <detail>
  if [ "$1" = "VERT" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
  RESULTS+=("$1 | $2 | $3")
  printf '%-6s %-46s %s\n' "$1" "$2" "$3"
}
diag_now() { count_diagnostics "$ENVDIR"; }
det() { plugin_diagnostics "$ENVDIR" | sed "s|.*plugins/$SLUG/||" | head -4 | tr '\n' ';'; }

say "=============================================================="
say "CAS : $VARIANT / WordPress $ENVN / PHP $PHPV"
say "=============================================================="

# --- preparation ------------------------------------------------------------
reset_env "$ENVDIR" "$PHPV"
if [ ! -f "$ENVDIR/wordpress/wp-content/database/wpenv.sqlite" ]; then
  res ROUGE "T0 preparation" "la base n'a pas ete reinstallee"
  say "VERDICT : ROUGE"; exit 1
fi
rm -rf "$ENVDIR/wordpress/wp-content/plugins/$SLUG"
# La variante "original" est le ZIP officiel telecharge par fetch-original.sh
# (verifie par md5) ; la variante "fixed" est le code de ce depot.
case "$VARIANT" in
  original) SRC="$BASE/original/$SLUG" ;;
  fixed)    SRC="$BASE/all-in-one-favicon" ;;
  *) echo "variante inconnue: $VARIANT" >&2; exit 2 ;;
esac
if [ ! -d "$SRC" ]; then
  say "VERDICT : ROUGE"
  echo "code source de la variante $VARIANT introuvable : $SRC" >&2
  [ "$VARIANT" = "original" ] && echo "lancez : bash fetch-original.sh" >&2
  exit 1
fi
cp -a "$SRC" "$ENVDIR/wordpress/wp-content/plugins/$SLUG"

# --- T1 : activation --------------------------------------------------------
BEFORE=$(diag_now)
OUT=$(wp "$ENVDIR" "$PHPV" plugin activate $SLUG 2>&1); RC=$?
AFTER=$(diag_now)
if [ "$RC" -ne 0 ]; then
  res ROUGE "T1 activation" "wp-cli a rendu $RC : $(echo "$OUT" | head -2 | tr '\n' ' ')"
elif echo "$OUT" | grep -qiE 'fatal error|parse error|uncaught'; then
  res ROUGE "T1 activation" "erreur fatale : $(echo "$OUT" | grep -iE 'fatal|uncaught' | head -1)"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T1 activation" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T1 activation" "aucune erreur fatale, 0 diagnostic"
fi
echo "$OUT" > "$LOGDIR/activation.txt"

# --- contenu de test --------------------------------------------------------
PAGE_ID=$(wp "$ENVDIR" "$PHPV" post create --post_title="Page de test AIOF" --post_status=publish \
  --post_content="<p>Page publique du harnais.</p>" --porcelain 2>/dev/null | lastid)
PERMALINK=$(wp "$ENVDIR" "$PHPV" post get "$PAGE_ID" --field=url 2>/dev/null | tr -d '\r\n')
[ -n "$PERMALINK" ] || PERMALINK="http://127.0.0.1:$PORT/?page_id=$PAGE_ID"
say "PAGE_ID=$PAGE_ID PERMALINK=$PERMALINK"
if [ -z "$PAGE_ID" ]; then
  res ROUGE "T0 preparation" "wp-cli n'a pas renvoye d'identifiant de page"
  say "VERDICT : ROUGE"; exit 1
fi

# --- serveur web ------------------------------------------------------------
if ! start_server "$ENVDIR" "$PHPV"; then
  res ROUGE "T2 serveur HTTP" "le serveur ne repond pas sur le port $PORT"
  say "VERDICT : ROUGE"; exit 1
fi
COOKIE=$(login_cookie "$ENVDIR" "$PHPV")

# --- T2 : front public ------------------------------------------------------
BEFORE=$(diag_now)
CODE=$(curl -s -o "$LOGDIR/front.html" -w '%{http_code}' "$PERMALINK" --max-time 60)
AFTER=$(diag_now)
if [ "$CODE" != "200" ]; then
  res ROUGE "T2 front public" "HTTP $CODE"
elif grep -qiE 'fatal error|uncaught (exception|error)' "$LOGDIR/front.html"; then
  res ROUGE "T2 front public" "erreur fatale dans la page"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T2 front public" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T2 front public" "HTTP 200, 0 diagnostic"
fi

# --- T3 : tableau de bord admin --------------------------------------------
BEFORE=$(diag_now)
CODE=$(curl -s -b "$COOKIE" -o "$LOGDIR/admin-index.html" -w '%{http_code}' \
       "http://127.0.0.1:$PORT/wp-admin/index.php" --max-time 60)
AFTER=$(diag_now)
if [ "$CODE" != "200" ]; then
  res ROUGE "T3 tableau de bord admin" "HTTP $CODE"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T3 tableau de bord admin" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T3 tableau de bord admin" "HTTP 200, 0 diagnostic"
fi

# --- T4 : ecran de reglages du plugin ---------------------------------------
BEFORE=$(diag_now)
CODE=$(curl -s -b "$COOKIE" -o "$LOGDIR/settings.html" -w '%{http_code}' \
       "http://127.0.0.1:$PORT/wp-admin/admin.php?page=all-in-one-favicon" --max-time 90)
AFTER=$(diag_now)
if [ "$CODE" != "200" ]; then
  res ROUGE "T4 ecran de reglages du plugin" "HTTP $CODE"
elif grep -qiE 'fatal error|uncaught (exception|error)' "$LOGDIR/settings.html"; then
  res ROUGE "T4 ecran de reglages du plugin" "erreur fatale dans la page"
elif ! grep -q 'aio-favicon-settings-update' "$LOGDIR/settings.html"; then
  res ROUGE "T4 ecran de reglages du plugin" "le formulaire de reglages est absent"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T4 ecran de reglages du plugin" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T4 ecran de reglages du plugin" "HTTP 200, formulaire present, 0 diagnostic"
fi

# --- T5 : enregistrement par le VRAI formulaire -----------------------------
# Le plugin enregistre par admin-post.php (action=aioFaviconUpdateSettings).
# On rejoue le formulaire tel que le navigateur l'enverrait : le nonce, le
# champ cache "action" et les champs de reglages sont pris dans la page.
ICO="http://127.0.0.1:$PORT/wp-content/uploads/2026/01/favicon-test.ico"
BEFORE=$(diag_now)
BODY=$(python3 "$BASE/tests/form-post.py" "$LOGDIR/settings.html" --form aio-favicon-settings-update \
        --set "aio-favicon_settings[frontendICO-text]=$ICO" \
        --set "aio-favicon_settings[removeLinkFromMetaBox]=1")
CODE=$(curl -s -b "$COOKIE" -o "$LOGDIR/save-settings.html" -w '%{http_code}' \
       -H "Content-Type: application/x-www-form-urlencoded" --data "$BODY" \
       "http://127.0.0.1:$PORT/wp-admin/admin-post.php" --max-time 90)
SAVED=$(wp "$ENVDIR" "$PHPV" option get aio-favicon_settings --format=json 2>/dev/null | tr -d '\r\n')
AFTER=$(diag_now)
if [ "$CODE" != "302" ] && [ "$CODE" != "200" ]; then
  res ROUGE "T5 enregistrement des reglages" "HTTP $CODE"
elif ! echo "$SAVED" | grep -q "favicon-test.ico"; then
  res ROUGE "T5 enregistrement des reglages" "les reglages n'ont pas ete enregistres (HTTP $CODE, option=[$SAVED])"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T5 enregistrement des reglages" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T5 enregistrement des reglages" "option aio-favicon_settings enregistree, 0 diagnostic"
fi

# --- T6 : suppression des reglages par le VRAI formulaire --------------------
BEFORE=$(diag_now)
BODY=$(python3 "$BASE/tests/form-post.py" "$LOGDIR/settings.html" --form delete_settings \
        --set "delete_settings-true=1")
CODE=$(curl -s -b "$COOKIE" -o "$LOGDIR/delete-settings.html" -w '%{http_code}' \
       -H "Content-Type: application/x-www-form-urlencoded" --data "$BODY" \
       "http://127.0.0.1:$PORT/wp-admin/admin-post.php" --max-time 90)
GONE=$(wp "$ENVDIR" "$PHPV" option get aio-favicon_settings --format=json 2>/dev/null | tr -d '\r\n')
AFTER=$(diag_now)
if [ "$CODE" != "302" ] && [ "$CODE" != "200" ]; then
  res ROUGE "T6 suppression des reglages" "HTTP $CODE"
elif echo "$GONE" | grep -q "favicon-test.ico"; then
  res ROUGE "T6 suppression des reglages" "les reglages n'ont pas ete supprimes (option=[$GONE])"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T6 suppression des reglages" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T6 suppression des reglages" "option supprimee, 0 diagnostic"
fi

# --- T7 : pages annexes du plugin ------------------------------------------
BEFORE=$(diag_now)
BAD=""
for U in "admin.php?page=all-in-one-favicon-plugin-other-tools" \
         "admin.php?page=aiof_go_appsumo_pro" \
         "options-general.php" \
         "upload.php"; do
  N=$(echo "$U" | tr '?=&/' '____')
  CODE=$(curl -s -b "$COOKIE" -o "$LOGDIR/extra-$N.html" -w '%{http_code}' \
         "http://127.0.0.1:$PORT/wp-admin/$U" --max-time 90)
  [ "$CODE" = "200" ] || [ "$CODE" = "302" ] || BAD="$BAD $U:$CODE"
  grep -qiE 'fatal error|uncaught (exception|error)' "$LOGDIR/extra-$N.html" 2>/dev/null && BAD="$BAD $U:fatal"
done
AFTER=$(diag_now)
if [ -n "$BAD" ]; then
  res ROUGE "T7 pages annexes du plugin" "HTTP non 200 :$BAD"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T7 pages annexes du plugin" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T7 pages annexes du plugin" "4 pages HTTP 200/302, 0 diagnostic"
fi

# --- T8 : rendu du favicon dans le <head> du front -------------------------
# On remet un favicon dans les reglages (par l'API du site, pas par le
# formulaire) puis on recharge le front : le plugin doit inserer la balise
# <link rel="icon"> dans le <head>.
wp "$ENVDIR" "$PHPV" option update aio-favicon_settings \
   --format=json "$(printf '{"frontendICO":"%s","backendICO":"%s","removeLinkFromMetaBox":true}' "$ICO" "$ICO")" \
   >/dev/null 2>&1
BEFORE=$(diag_now)
CODE=$(curl -s -o "$LOGDIR/front-favicon.html" -w '%{http_code}' "$PERMALINK" --max-time 60)
AFTER=$(diag_now)
if [ "$CODE" != "200" ]; then
  res ROUGE "T8 rendu du favicon (front)" "HTTP $CODE"
elif ! grep -qiE '<link[^>]+rel=["'"'"']?(shortcut )?icon' "$LOGDIR/front-favicon.html"; then
  res ROUGE "T8 rendu du favicon (front)" "aucune balise <link rel=icon> dans le head"
elif [ "$AFTER" -gt "$BEFORE" ]; then
  res ROUGE "T8 rendu du favicon (front)" "$((AFTER-BEFORE)) diagnostic(s) : $(det)"
else
  res VERT "T8 rendu du favicon (front)" "balise <link rel=icon> presente, 0 diagnostic"
fi

stop_server "$ENVDIR"

# --- conservation des preuves ------------------------------------------------
cp -f "$ENVDIR/server.log" "$LOGDIR/server.log" 2>/dev/null || true
cp -f "$ENVDIR/wordpress/wp-content/debug.log" "$LOGDIR/debug.log" 2>/dev/null || true
plugin_diagnostics "$ENVDIR" > "$LOGDIR/debug.log.plugin-only.txt" 2>/dev/null || true

# --- verdict ----------------------------------------------------------------
say ""
say "RESULTATS : $PASS vert(s), $FAIL rouge(s)"
printf '%s\n' "${RESULTS[@]}" > "$LOGDIR/resultats.txt"
if [ "$FAIL" -eq 0 ]; then
  say "VERDICT : VERT"
  exit 0
else
  say "VERDICT : ROUGE"
  exit 1
fi
