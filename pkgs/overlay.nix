# Overlay: our own packages, available as pkgs.<name> on every host.
inputs: final: _prev: {
  orchard = final.callPackage ./orchard { };
  niXscout = final.callPackage ./nixscout { };
  nyaa-si = final.callPackage ./nyaa-si { src = inputs.nyaa-si-src; };
  neo-mangal = final.callPackage ./neo-mangal { src = inputs.neo-mangal-src; };
  vid-dl = final.callPackage ./vid-dl { };
  localsend-cli = final.callPackage ./localsend-cli { };
  matugen = final.callPackage ./matugen { };
}
