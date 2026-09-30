{ lib
, stdenvNoCC
, catppuccin-sddm
}:

stdenvNoCC.mkDerivation {
  pname = "catppuccin-sddm-osk";
  version = "0";

  src = catppuccin-sddm;

  dontConfigure = true;
  dontBuild = true;

  # No runHook prePatch/postPatch here on purpose: calling substituteInPlace
  # between them makes the stdenv builder segfault under the Nix sandbox
  # (builder killed by signal 11 in patchPhase). stdenv already runs the hooks
  # around this phase, so invoking them again is both redundant and the thing
  # that crashes.
  postPatch = ''
    panel="share/sddm/themes/catppuccin-mocha-mauve/Components/LoginPanel.qml"

    # InputPanel is a QtQuick.VirtualKeyboard type, so the module has to be
    # imported before the theme can use it.
    substituteInPlace "$panel" \
      --replace-fail 'import "../assets"' 'import "../assets"
    import QtQuick.VirtualKeyboard 2.15'

    # The power and session columns are anchored to the bottom corners, which is
    # exactly where the keyboard lands, so lift them onto its top edge. The
    # dotted sed expression matches the literal text here: substituteInPlace
    # would treat it as a regex, where an unescaped dot also matches any
    # character and an escaped one does not survive its own quoting.
    sed -i 's/bottom: parent\.bottom/bottom: inputPanel.top/g' "$panel"

    # The panel itself goes just inside the root Item's closing brace.
    cat > panel.qml <<'EOF'

  InputPanel {
    id: inputPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    z: 10
    visible: true
  }
}
EOF
    head -n -1 "$panel" > panel.old
    cat panel.old panel.qml > "$panel"
    rm -f panel.old panel.qml
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out"
    runHook postInstall
  '';

  meta = {
    description = "Catppuccin SDDM theme with an on-screen keyboard for touch";
    platforms = lib.platforms.all;
  };
}
