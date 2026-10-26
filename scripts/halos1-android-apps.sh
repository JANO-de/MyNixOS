#!/usr/bin/env bash
# Install F-Droid, Aurora Store and microG (GmsCore + GsfProxy) into Droidloom (C6). Runs ON halos1, from the PC:
#   ssh halos1 'bash -s' < scripts/halos1-android-apps.sh
# Needs Droidloom running (droidloomctl start) and internet on halos1.
set -euo pipefail
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT
droidloomctl status 2>&1 | grep -qi "running" || { echo "Droidloom is not running: droidloomctl start"; exit 1; }

get() { # <package id> -> $D/<id>.apk (latest suggested version from the F-Droid repo)
  local vc
  vc=$(curl -fsSL "https://f-droid.org/api/v1/packages/$1" | grep -o '"suggestedVersionCode": *[0-9]*' | grep -o '[0-9]*$' | head -n1)
  [ -n "$vc" ] || { echo "no version found for $1"; return 1; }
  echo "$1 versionCode $vc"
  curl -fL --progress-bar -o "$D/$1.apk" "https://f-droid.org/repo/${1}_${vc}.apk"
  [ "$(head -c2 "$D/$1.apk")" = "PK" ] || { echo "$1: not an APK"; return 1; }
}

for p in org.fdroid.fdroid com.aurora.store; do
  get "$p" && droidloomctl install "$D/$p.apk"
done

# microG has its own F-Droid repo (index-v1.json): newest APK that is architecture-neutral or has x86_64.
IDX=$(curl -fsSL https://microg.org/fdroid/repo/index-v1.json)
for p in com.google.android.gms com.google.android.gsf; do
  f=$(printf '%s' "$IDX" | jq -r --arg p "$p" '[.packages[$p][] | select((.nativecode == null) or (.nativecode | index("x86_64")))] | sort_by(.versionCode) | last | .apkName')
  [ -n "$f" ] && [ "$f" != null ] || { echo "microG: no APK for $p"; continue; }
  echo "$p -> $f"
  curl -fL --progress-bar -o "$D/$p.apk" "https://microg.org/fdroid/repo/$f"
  [ "$(head -c2 "$D/$p.apk")" = "PK" ] && droidloomctl install "$D/$p.apk"
done
echo "microG needs signature spoofing, which this image lacks: open microG Settings > Self-Check to see what works."
echo "--- installed (launchers):"
droidloomctl applications 2>&1 | grep -i -E "f-droid|fdroid|aurora|microg" || echo "not listed yet: wait 10 s and run: droidloomctl applications"
