#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
apply-compat-patch.py - correctif de COMPATIBILITE du plugin
"All In One Favicon" 4.8 (code officiel wordpress.org).

Usage :
    python3 apply-compat-patch.py <dossier-source> <dossier-cible>

Le correctif ne fait QUE deux choses, toutes deux purement de compatibilite :

 1) DECLARER les proprietes que les classes creaient dynamiquement.
    En PHP 8.2+, creer une propriete non declaree est une
    "Deprecated: Creation of dynamic property". Declarer une propriete
    qui existe deja ne change AUCUN comportement : la valeur, le type et
    l'ordre des affectations restent identiques.

 2) REMPLACER create_function() (supprimee en PHP 8.0) par une closure
    equivalente. Le code de la branche est mort dans l'interface actuelle
    (l'URL de l'ecran de reglages ne contient pas 'all-in-one-favicon.php'),
    mais l'appel serait un "Fatal error" sur PHP 8 s'il devenait
    atteignable.

Aucune fonctionnalite ajoutee, aucune option, aucun texte visible change.
"""
import os
import shutil
import sys

# (fichier relatif, ancien texte, nouveau texte)
PATCHES = [
    # ------------------------------------------------------------------ 1) AllInOneFavicon
    (
        "all-in-one-favicon.php",
        "class AllInOneFavicon {\n",
        "class AllInOneFavicon {\n"
        "\n"
        "  /**\n"
        "   * Compatibility (PHP >= 8.2): these properties were created dynamically by the\n"
        "   * original code, which raises\n"
        "   * \"Deprecated: Creation of dynamic property ...\" on every request.\n"
        "   * Declaring them changes no behaviour at all.\n"
        "   */\n"
        "  public $aioFaviconSettings;\n"
        "  public $aioFaviconFrontendMap;\n"
        "  public $aioFaviconBackendMap;\n",
    ),
    # ------------------------------------------------------------------ 2) AioFaviconBackend
    (
        "includes/aio-favicon-backend.php",
        "class AioFaviconBackend {\n",
        "class AioFaviconBackend {\n"
        "\n"
        "  /**\n"
        "   * Compatibility (PHP >= 8.2): these properties were created dynamically by the\n"
        "   * original code, which raises\n"
        "   * \"Deprecated: Creation of dynamic property ...\" on every request.\n"
        "   * Declaring them changes no behaviour at all.\n"
        "   */\n"
        "  public $aioFaviconSettings;\n"
        "  public $aioFaviconDefaultSettings;\n"
        "  public $donationLoader;\n"
        "  public $faviconRenderHelper;\n"
        "  public $faviconFrontendMap;\n"
        "  public $faviconBackendMap;\n"
        "  public $faviconMap;\n"
        "  public $identifier;\n"
        "  public $translatedIdentifier;\n",
    ),
    # ------------------------------------------------------------------ 3) AioFaviconFrontend
    (
        "includes/aio-favicon-frontend.php",
        "class AioFaviconFrontend {\n",
        "class AioFaviconFrontend {\n"
        "\n"
        "  /**\n"
        "   * Compatibility (PHP >= 8.2): these properties were created dynamically by the\n"
        "   * original code, which raises\n"
        "   * \"Deprecated: Creation of dynamic property ...\" on every request.\n"
        "   * Declaring them changes no behaviour at all.\n"
        "   */\n"
        "  public $aioFaviconSettings;\n"
        "  public $faviconRenderHelper;\n",
    ),
    # ------------------------------------------------------------------ 4) FaviconRenderHelper
    (
        "includes/favicon-render-helper.php",
        "class FaviconRenderHelper {\n",
        "class FaviconRenderHelper {\n"
        "\n"
        "  /**\n"
        "   * Compatibility (PHP >= 8.2): these properties were created dynamically by the\n"
        "   * original code, which raises\n"
        "   * \"Deprecated: Creation of dynamic property ...\" on every request.\n"
        "   * Declaring them changes no behaviour at all.\n"
        "   */\n"
        "  public $aioFaviconSettings;\n"
        "  public $aioFaviconType;\n",
    ),
    # ------------------------------------------------------------------ 5) create_function()
    (
        "includes/aio-favicon-backend.php",
        "      add_action('admin_notices', create_function('', \"echo '$message';\"));\n",
        "      // Compatibility (PHP >= 8.0): create_function() was removed in PHP 8.0 and\n"
        "      // calling it is a fatal error. The closure below does exactly what the\n"
        "      // generated function did: it echoes the very same $message string.\n"
        "      add_action('admin_notices', function () use ($message) { echo $message; });\n",
    ),
    # ------------------------------------------------------------------ 6) deleteFile()
    (
        "includes/aio-favicon-backend.php",
        "    $url = $this->aioFaviconSettings[$faviconName];\n",
        "    // Compatibility (PHP >= 8.0 / 8.1): the settings array does not always hold\n"
        "    // every favicon type, so this read used to raise\n"
        "    // \"Warning: Undefined array key\" and then\n"
        "    // \"Deprecated: str_replace(): Passing null to parameter #3\".\n"
        "    // In PHP 7 the very same NULL was read (with a notice) and str_replace\n"
        "    // turned it into ''; the branch below was therefore already skipped.\n"
        "    $url = isset( $this->aioFaviconSettings[$faviconName] ) ? $this->aioFaviconSettings[$faviconName] : '';\n",
    ),
]


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("usage: apply-compat-patch.py <source> <cible>\n")
        return 2
    src, dst = sys.argv[1], sys.argv[2]
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    touched = 0
    for rel, old, new in PATCHES:
        path = os.path.join(dst, rel)
        with open(path, "rb") as f:
            data = f.read()
        ob, nb = old.encode("utf-8"), new.encode("utf-8")
        n = data.count(ob)
        if n != 1:
            sys.stderr.write("PATCH IMPOSSIBLE (%d occurrences) : %s\n" % (n, rel))
            return 3
        with open(path, "wb") as f:
            f.write(data.replace(ob, nb))
        touched += 1
    print("PATCH APPLIQUE : %d remplacements sur %d fichiers"
          % (touched, len({p[0] for p in PATCHES})))
    return 0


if __name__ == "__main__":
    sys.exit(main())
