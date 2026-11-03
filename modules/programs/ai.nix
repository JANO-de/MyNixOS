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
      extraFlags = [
        "--models-max"
        "1"
      ];

      modelsPreset = {
        "qwen3-8b" = {
          model = "/var/lib/llama-models/Qwen3-8B-Q4_K_M.gguf";
          alias = "qwen3-8b";
          ctx-size = "8192";
          fit-target = "640";
          temp = "0.6";
          top-p = "0.95";
          top-k = "20";
        };
        "qwen3-14b" = {
          model = "/var/lib/llama-models/Qwen3-14B-Q4_K_M.gguf";
          alias = "qwen3-14b";
          ctx-size = "8192";
          fit-target = "640";
          temp = "0.6";
          top-p = "0.95";
          top-k = "20";
        };
      };
    };
  };
}
