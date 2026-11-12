# Local AI: llama.cpp server (Vulkan) with two Qwen3 models, Forge TUI and the `llm` alias.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.ai;
  llama = pkgs.llama-cpp.override { vulkanSupport = true; };
in
{
  options.modules.programs.ai.enable =
    lib.mkEnableOption "local AI (llama.cpp server, Forge, llm alias)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ llama ];

    programs.forge.enable = true;
    environment.shellAliases.llm = "$HOME/.local/bin/llm";

    services.llama-cpp = {
      enable = true;
      package = llama;
      port = 8081; # Changed port from 8080 to 8081
      extraFlags = [
        "--models-max"
        "1"
      ];

      modelsPreset = {
        "qwen3-8b-unsloth" = {
          model = "/var/lib/llama-models/Qwen3-8B-unsloth-Q4_K_M.gguf";
          alias = "qwen3-8b-unsloth";
          ctx-size = "4096";
          fit-target = "256";
          temp = "0.6";
          top-p = "0.95";
          top-k = "20";
        };

        "qwen3-8b-abliterated" = {
          model = "/var/lib/llama-models/Huihui-Qwen3-8B-abliterated-v2.Q4_K_M.gguf";
          alias = "qwen3-8b-abliterated";
          ctx-size = "4096";
          fit-target = "256";
          temp = "0.6";
          top-p = "0.95";
          top-k = "20";
        };

        "dolphin3-8b" = {
          model = "/var/lib/llama-models/Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf";
          alias = "dolphin3-8b";
          ctx-size = "4096";
          fit-target = "256";
          temp = "0.8";
          top-p = "0.95";
        };
      };
    };
  };
}
