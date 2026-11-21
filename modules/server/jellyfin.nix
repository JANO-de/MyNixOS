# Jellyfin: media server. Data, cache and the media library live on the
# "storage" dual-disk btrfs pool; NVENC/NVDEC transcode on the GTX 1060.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.jellyfin;
  jf = config.services.jellyfin;
in
{
  options.modules.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server (data + cache + media on /mnt/storage, NVENC on the NVIDIA GPU)";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/storage/jellyfin";
      description = "Jellyfin data, config and log directory.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/storage/jellyfin/cache";
      description = "Jellyfin transcoding cache directory.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/storage/media";
      description = "Directory holding the media library, readable by the Jellyfin user.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      dataDir = cfg.dataDir;
      cacheDir = cfg.cacheDir;
      openFirewall = true;

      hardwareAcceleration = {
        enable = true;
        type = "nvenc";
        device = "/dev/nvidia0";
      };

      # GTX 1060 (Pascal): H.264 + HEVC encode/decode, VP9 decode. No AV1.
      transcoding = {
        enableHardwareEncoding = true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          vp9 = true;
        };
        hardwareEncodingCodecs.hevc = true;
      };
    };

    # systemd-tmpfiles refuses to create jellyfin-owned dirs below the
    # jano-owned /mnt/storage ("unsafe path transition"), so the upstream
    # tmpfiles rules only materialise dataDir; config/log/cache must be
    # created here, as the service user, before the upstream pre-start
    # copies encoding.xml into config/.
    systemd.services.jellyfin = {
      serviceConfig.ExecStartPre = lib.mkBefore [
        (pkgs.writeShellScript "jellyfin-dirs" ''
          install -d -m 700 -- '${jf.configDir}' '${jf.logDir}' '${jf.cacheDir}'
        '')
      ];
      serviceConfig = {
        # NVENC needs the other NVIDIA nodes too; the module only whitelists `device`.
        DeviceAllow = [
          "/dev/nvidiactl rw"
          "/dev/nvidia-uvm rw"
          "/dev/nvidia-uvm-tools rw"
          "/dev/nvidia-modeset rw"
        ];
        # The proprietary driver does not initialise inside the private user namespace.
        PrivateUsers = lib.mkForce false;
      };
    };

    # Jellyfin only reads the library; keep it owned by the normal user.
    systemd.tmpfiles.settings.jellyfinMedia = {
      "${cfg.mediaDir}"."d" = {
        mode = "0775";
        user = "jano";
        group = "users";
      };
    };
  };
}
