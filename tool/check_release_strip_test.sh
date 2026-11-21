#!/usr/bin/env bash
# Self test for tool/check_release_strip.sh on fake release builds (no Flutter build needed).
# Run: bash tool/check_release_strip_test.sh
# The real-build proof (guard removed -> gate fails) runs in .github/workflows/desktop-it.yml.
set -u
cd "$(dirname "$0")/.."
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# expect NAME WANT_EXIT TARGET
expect() {
  local name="$1" want="$2" target="$3" got
  bash tool/check_release_strip.sh "$target" >/dev/null 2>&1
  got=$?
  if [ "$got" = "$want" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: want exit $want, got $got"; fail=1
  fi
}

mk() { mkdir -p "$(dirname "$1")"; printf '%s' "$2" >"$1"; }
clean='AOT snapshot without the debug prefix'
leaky='AOT snapshot ... ext.mitlio.ping ... registerExtension'

mk "$tmp/linux_ok/lib/libapp.so" "$clean"
mk "$tmp/linux_leak/lib/libapp.so" "$leaky"
mk "$tmp/ios_ok/Runner.app/Frameworks/App.framework/App" "$clean"
mk "$tmp/ios_leak/Runner.app/Frameworks/App.framework/App" "$leaky"
mk "$tmp/leak_elsewhere/lib/libapp.so" "$clean"
mk "$tmp/leak_elsewhere/data/flutter_assets/kernel_blob.bin" "$leaky"
mk "$tmp/no_snapshot/readme" "$clean"
mk "$tmp/debug_kernel/flutter_assets/kernel_blob.bin" "$leaky"

expect "linux bundle without prefix passes" 0 "$tmp/linux_ok"
expect "linux bundle with prefix fails" 1 "$tmp/linux_leak"
expect "ios app without prefix passes" 0 "$tmp/ios_ok"
expect "ios app with prefix fails" 1 "$tmp/ios_leak"
expect "prefix in another file of the bundle fails" 1 "$tmp/leak_elsewhere"
expect "build without AOT snapshot is rejected, not passed" 2 "$tmp/no_snapshot"
expect "debug build (kernel blob only) is rejected" 2 "$tmp/debug_kernel"
expect "missing path is rejected" 2 "$tmp/does_not_exist"

if ! command -v zip >/dev/null 2>&1; then
  echo "FAIL: zip is not installed, the apk/aab/ipa cases cannot run (install zip, e.g. apt-get install zip)" >&2
  exit 1
fi
(cd "$tmp/linux_ok" && zip -qr "$tmp/ok.apk" lib)
(cd "$tmp/linux_leak" && zip -qr "$tmp/leak.apk" lib)
(cd "$tmp/ios_leak" && zip -qr "$tmp/leak.ipa" Runner.app)
mk "$tmp/aab_ok/base/lib/arm64-v8a/libapp.so" "$clean"
mk "$tmp/aab_leak/base/lib/arm64-v8a/libapp.so" "$leaky"
(cd "$tmp/aab_ok" && zip -qr "$tmp/ok.aab" base)
(cd "$tmp/aab_leak" && zip -qr "$tmp/leak.aab" base)
expect "apk without prefix passes" 0 "$tmp/ok.apk"
expect "apk with prefix fails" 1 "$tmp/leak.apk"
expect "ipa with prefix fails" 1 "$tmp/leak.ipa"
expect "aab without prefix passes" 0 "$tmp/ok.aab"
expect "aab with prefix fails" 1 "$tmp/leak.aab"
mk "$tmp/notes.txt" "$clean"
expect "unsupported file type is rejected" 2 "$tmp/notes.txt"

exit "$fail"
