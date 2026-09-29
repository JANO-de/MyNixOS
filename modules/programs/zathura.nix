{ config, pkgs, lib, ... }:

# zathura — the small keyboard-driven PDF viewer.
#
# It is the right default on a tablet: it opens instantly, takes pen input
# without the scroll-jitter fight a heavier viewer has, and the mupdf backend
# renders scanned pages noticeably faster than poppler. Poppler stays enabled
# for the PDFs that need its quirks (odd page sizes, broken xref tables).
{
  environment.systemPackages = lib.optionals config.modules.programs.zathura.enable [
    # The stock wrapper ships djvu/ps/cb on top of these; the tablet only needs
    # the two PDF backends, so the plugin set is narrowed to keep the closure
    # smaller.
    (
      pkgs.zathura.override {
        plugins = with pkgs.zathuraPkgs; [
          zathura_pdf_mupdf
          zathura_pdf_poppler
        ];
      }
    )
  ];
}
