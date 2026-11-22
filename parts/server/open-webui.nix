# Open WebUI: chat front end for the local llama.cpp server (services.llama-cpp, :8081).
# Listens on localhost only; reach it through Caddy at https://<tailnet-name>:18082.
# First account you create becomes the admin.
_: {
  flake.nixosModules.server-open-webui =
    { config, lib, ... }:

    let
      cfg = config.modules.services.openWebui;
    in
    {
      options.modules.services.openWebui.enable = lib.mkEnableOption "Open WebUI for llama.cpp";

      config = lib.mkIf cfg.enable {
        services.open-webui = {
          enable = true;
          host = "127.0.0.1";
          port = 8082;
          environment = {
            # llama-server speaks the OpenAI API; it ignores the key.
            OPENAI_API_BASE_URL = "http://127.0.0.1:8081/v1";
            OPENAI_API_KEY = "none";
            ENABLE_OLLAMA_API = "False";
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
            HOME = "/var/lib/open-webui";
          };
        };
      };
    };
}
