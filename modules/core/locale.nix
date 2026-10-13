{ ... }:

{
  time.timeZone = "Europe/Madrid";

  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = builtins.listToAttrs (map
    (n: { name = "LC_${n}"; value = "es_ES.UTF-8"; })
    [ "ADDRESS" "IDENTIFICATION" "MEASUREMENT" "MONETARY" "NAME" "NUMERIC" "PAPER" "TELEPHONE" "TIME" ]);

  console.keyMap = "es";
}
