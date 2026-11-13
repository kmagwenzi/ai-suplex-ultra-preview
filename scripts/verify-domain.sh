#!/usr/bin/env bash
# verify-domain.sh — acceptance test for the Netlify domains.
# Usage: ./scripts/verify-domain.sh [--all | --www | --wqr]
set -u

LB="75.2.60.5"
TEST_WWW=0
TEST_WQR=0
for arg in "$@"; do
  case "$arg" in
    --all) TEST_WWW=1; TEST_WQR=1 ;;
    --www) TEST_WWW=1 ;;
    --wqr) TEST_WQR=1 ;;
  esac
done

pass=0
fail=0

check() { # check <1|0> <message>
  if [ "$1" = "1" ]; then
    printf "  PASS  %s\n" "$2"
    pass=$((pass + 1))
  else
    printf "  FAIL  %s\n" "$2"
    fail=$((fail + 1))
  fi
}

note() { printf "  note  %s\n" "$1"; }

verify_host() { # verify_host <host> <body-marker>
  h="$1"
  marker="$2"
  echo ""
  echo "== $h"

  cname=$(dig +short CNAME "$h" 2>/dev/null | head -1)
  a=$(dig +short A "$h" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
  aaaa=$(dig +short AAAA "$h" 2>/dev/null | grep ':' | head -1)

  if [ -n "$cname" ]; then
    note "CNAME -> $cname"
    case "$cname" in
      *netlify.app*)
        check 0 "CNAME points into *.netlify.app (unreachable on this network)"
        ;;
      *)
        check 1 "CNAME chain present, not *.netlify.app"
        ;;
    esac
  fi

  if [ "$a" = "$LB" ]; then
    check 1 "A record is $LB"
  elif [ -n "$a" ]; then
    check 0 "A record is $a (want $LB)"
  else
    check 0 "no A record (want $LB)"
  fi

  if [ -n "$aaaa" ]; then
    note "AAAA present: $aaaa (also verify it answers)"
  fi

  if timeout 10 bash -c "echo > /dev/tcp/$h/443" 2>/dev/null; then
    check 1 "TCP 443 reachable"
  else
    check 0 "TCP 443 unreachable"
    return 0
  fi

  tls=$(timeout 15 openssl s_client -servername "$h" -connect "$h:443" -verify_return_error < /dev/null 2>/dev/null \
        | grep "Verify return code" | head -1)
  case "$tls" in
    *"Verify return code: 0"*) check 1 "TLS certificate valid for $h" ;;
    *) check 0 "TLS problem: $tls" ;;
  esac

  body=$(mktemp)
  code=$(curl -s -o "$body" -w "%{http_code}" --max-time 25 "https://$h/" 2>/dev/null)
  if [ "$code" = "200" ]; then
    check 1 "HTTPS 200"
  else
    check 0 "HTTPS returned $code"
  fi

  if grep -qi "$marker" "$body" 2>/dev/null; then
    check 1 "body contains the expected page ($marker)"
  else
    check 0 "body does not contain $marker"
  fi

  loc=$(curl -sI --max-time 20 "https://$h/" 2>/dev/null | grep -i "^location:" | head -1)
  case "$loc" in
    *netlify.app*) check 0 "redirects back into *.netlify.app: $loc" ;;
    *) check 1 "no redirect into *.netlify.app" ;;
  esac

  rm -f "$body"
  return 0
}

verify_alias() { # verify_alias <host> <body-marker> — a host that legitimately redirects
  h="$1"
  marker="$2"
  echo ""
  echo "== $h (alias — may redirect)"

  a=$(dig +short A "$h" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
  cname=$(dig +short CNAME "$h" 2>/dev/null | head -1)
  if [ -n "$cname" ] && [ "$cname" != "" ]; then
    case "$cname" in
      *netlify.app*) check 0 "CNAME points into *.netlify.app: $cname" ;;
    esac
  fi

  if [ "$a" = "$LB" ]; then
    check 1 "A record is $LB"
  elif [ -n "$a" ]; then
    check 0 "A record is $a (want $LB)"
  else
    check 0 "no A record (want $LB)"
  fi

  if timeout 10 bash -c "echo > /dev/tcp/$h/443" 2>/dev/null; then
    check 1 "TCP 443 reachable"
  else
    check 0 "TCP 443 unreachable"
    return 0
  fi

  tls=$(timeout 15 openssl s_client -servername "$h" -connect "$h:443" -verify_return_error < /dev/null 2>/dev/null \
        | grep "Verify return code" | head -1)
  case "$tls" in
    *"Verify return code: 0"*) check 1 "TLS certificate valid for $h" ;;
    *) check 0 "TLS problem: $tls" ;;
  esac

  body=$(mktemp)
  out=$(curl -sL -o "$body" -w "%{http_code} %{url_effective}" --max-time 25 "https://$h/" 2>/dev/null)
  code=${out%% *}
  final=${out##* }
  if [ "$code" = "200" ]; then
    check 1 "resolves to a 200 (final: $final)"
  else
    check 0 "final response $code (final: $final)"
  fi

  case "$final" in
    *netlify.app*) check 0 "lands on *.netlify.app: $final" ;;
    *) check 1 "does not land on *.netlify.app" ;;
  esac

  if grep -qi "$marker" "$body" 2>/dev/null; then
    check 1 "body contains the expected page ($marker)"
  else
    note "body marker '$marker' not found (alias may serve a login shell)"
  fi

  rm -f "$body"
  return 0
}

echo "=== domain verification · $(date -u +%Y-%m-%dT%H:%MZ) ==="
echo "edge target: $LB"

verify_host "ultra.ai-suplex.co.zw" "Ultra"
if [ "$TEST_WWW" = "1" ]; then verify_host "www.ai-suplex.co.zw" "AI-Suplex"; fi
if [ "$TEST_WQR" = "1" ]; then
  verify_host "wqr.co.zw" "Quick Responder"
  verify_alias "www.wqr.co.zw" "quick responder"
  verify_alias "app.wqr.co.zw" "wqr"
fi

echo ""
echo "--- $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  echo "PENDING: DOMAIN.md section 3 (the three fixes)."
  exit 1
fi
echo "WIRED: every tested host answers from the reachable Netlify edge."
exit 0
