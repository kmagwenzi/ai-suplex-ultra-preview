# Wiring the Netlify domains — ultra.ai-suplex.co.zw, and the two that are already broken

**Measured 2026-11-11.** One record to create, one site to add, and **two live domains pointing at addresses this network cannot reach**.

---

## 1 · What is true right now

| Host | DNS | Reachable? |
|---|---|---|
| **ai-suplex.co.zw** (apex) | A **75.2.60.5** | **200** — the labs site |
| **www.ai-suplex.co.zw** | CNAME → ai-suplex-labs.netlify.app → 35.157.26.135 · 63.176.8.218 + IPv6 | **timeout** |
| **wqr.co.zw** (live product) | A 63.176.8.218 · 35.157.26.135 (Netlify DNS) | **timeout** |
| **ultra.ai-suplex.co.zw** | **no record at all** | does not resolve |
| ai-suplex-ultra-preview.netlify.app | 35.157.26.135 · 63.176.8.218 | **timeout** |
| the same preview via an external fetcher | — | **200, 7,128 bytes** |

---

## 2 · The finding

**Netlify is serving custom domains from two edge addresses this network cannot reach — 63.176.8.218 and 35.157.26.135 — while 75.2.60.5 works.**

Proof, not inference:

- The Ultra preview is **up**: an external fetcher returns it (200, title "AI-Suplex Ultra — The harness that compounds"). Every local connection to its two A records times out — with the correct Host header, over HTTP and HTTPS, at the TCP level.
- **wqr.co.zw** answers **200** when forced at 75.2.60.5:
  ~~~bash
  curl --resolve wqr.co.zw:443:75.2.60.5 https://wqr.co.zw/
  # http=200, title "WhatsApp Quick Responder (WQR) — by AI-Suplex Labs"
  ~~~
- The apex works because it is the **only** one of the four pointing at 75.2.60.5.
- netlify.com, app.netlify.com and github.com answer normally from the same machine, so this is not an outage, not a firewall on all traffic, and not this site.

**Read it plainly: wqr.co.zw and www.ai-suplex.co.zw are down for visitors on this network today.** The sites are fine. The addresses are not.

---

## 3 · The three fixes

| Host | Where | Change | Time |
|---|---|---|---|
| **wqr.co.zw** | **Netlify DNS** (you have the account) | A @ → **75.2.60.5** | 5 min, self-service |
| **ultra.ai-suplex.co.zw** | Netlify site (add domain) **+** WebZim (A record) | add domain · A ultra → 75.2.60.5 | your part 5 min, WebZim unknown |
| **www.ai-suplex.co.zw** | WebZim | CNAME → **A 75.2.60.5** | same ticket |

---

## 4 · wqr.co.zw — do this first (5 minutes, no ticket)

It is the live product surface, it is dead locally, and the zone is on **Netlify DNS** (dns1–dns4.p02.nsone.net), so no one else has to act.

1. Netlify → **Domains** → **wqr.co.zw** → **DNS records**.
2. Edit the apex **A** record to **75.2.60.5**; delete any other apex A records.
3. Leave MX/SPF/TXT and the www record alone unless www is also aimed at the two bad IPs — check it while you are there.
4. Wait 2–5 minutes, then:

~~~bash
dig +short A wqr.co.zw          # expect: 75.2.60.5
curl -sI https://wqr.co.zw/     # expect: HTTP/2 200
~~~

If Netlify marks the record as manager-owned and will not let you edit it, remove and re-add the domain on the site so Netlify re-provisions, then edit again. Re-check a day later: Netlify sometimes restores its preferred records.

---

## 5 · ultra.ai-suplex.co.zw — the new front door

**Order matters: Netlify first, DNS second.**

1. **Netlify** → site **ai-suplex-ultra-preview** → *Domain management* → *Add a domain* → **ultra.ai-suplex.co.zw**. Ignore the CNAME it suggests.
2. **WebZim** → create **A ultra → 75.2.60.5**, TTL 3600 (ticket in section 7).
3. Netlify issues the TLS certificate once the name resolves to it — usually minutes after propagation.

Why not the CNAME Netlify suggests: it resolves into the two unreachable addresses (section 2). A record, or — if WebZim's panel refuses an A on a subdomain — **CNAME ultra → ai-suplex.co.zw**, which rides the apex's working A. Never a CNAME to *.netlify.app.

**Netlify API**, if you would rather not click (keep the token out of git):

~~~bash
TOKEN=...
SITE=$(curl -s -H "Authorization: Bearer $TOKEN" https://api.netlify.com/api/v1/sites \
  | python3 -c 'import sys,json;print(next(s["id"] for s in json.load(sys.stdin) if s["name"]=="ai-suplex-ultra-preview"))')

curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"domain":"ultra.ai-suplex.co.zw"}' \
  "https://api.netlify.com/api/v1/sites/$SITE/domains"

curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"custom_domain":"ultra.ai-suplex.co.zw"}' \
  "https://api.netlify.com/api/v1/sites/$SITE"
~~~

---

## 6 · www.ai-suplex.co.zw

Currently a CNAME into the blocked range. In the same WebZim ticket: replace it with **A www → 75.2.60.5**, and add www as a domain on the **ai-suplex-labs** Netlify site so it redirects to the apex.

---

## 7 · The WebZim ticket

~~~text
Subject: ai-suplex.co.zw — two DNS records (A records, not CNAMEs)

Account: ai-suplex.co.zw (ns1/ns2.webzim.net)

Please add / change two records. Both are A records deliberately: the CNAME
targets resolve to addresses that are unreachable on some Zimbabwean networks,
which is why we cannot use them.

1) ADD
   Type:   A
   Host:   ultra
   Value:  75.2.60.5
   TTL:    3600

2) CHANGE (currently a CNAME to ai-suplex-labs.netlify.app)
   Type:   A
   Host:   www
   Value:  75.2.60.5
   TTL:    3600

Leave the apex A record (75.2.60.5), the MX records (mx.zoho.com, mx2, mx3),
SPF and the existing TXT records exactly as they are.

Please confirm when both are live at ns1 and ns2.

Kudakwashe Magwenzi · AI-Suplex Labs · ai-suplex.co.zw · +263 78 221 7266
~~~

---

## 8 · Acceptance test

~~~bash
./scripts/verify-domain.sh              # ultra
./scripts/verify-domain.sh --all        # ultra + www + wqr
./scripts/verify-domain.sh --wqr        # the live product only
~~~

Passes when: the A record is 75.2.60.5 (not a CNAME into *.netlify.app), TCP 443 is reachable, TLS validates for the hostname, HTTPS returns 200, the body is the right page, and nothing redirects back into the blocked range.

---

## 9 · After it answers

Move **canonical** and **og:url** in index.html to https://ultra.ai-suplex.co.zw/ — but only once the name answers. Pointing them at a dead host tells search engines the page lives nowhere. The same applies to the Ultra links already shared in outreach and posts, which today point at *.netlify.app: swap them once the domain is live.

## 10 · Rollback

Delete the **ultra** record. The site returns to its *.netlify.app name — unreachable here, fine elsewhere. Nothing is deployed into the domain: the page is static, no logic reads the hostname.
