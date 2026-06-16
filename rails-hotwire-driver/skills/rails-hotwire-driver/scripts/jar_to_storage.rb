#!/usr/bin/env ruby
# frozen_string_literal: true
#
# jar_to_storage.rb — bridge an authenticated curl session over to Playwright.
#
# Reads the Netscape cookie jar that req.sh / submit_form.rb / flow.sh maintain
# and emits Playwright "storageState" JSON. Seed any Playwright flavor with it:
#
#   Playwright MCP / test runner:  browser.newContext({ storageState: 'state.json' })
#   playwright-ruby-client:        browser.new_context(storageState: 'state.json')
#
# Typical use — authenticate fast with the OTP-from-log trick, then hand the
# logged-in session to a real browser for JS/DOM verification:
#
#   flow.sh --email me@x.com --otp-path /session/otp --then-path /  # logs in
#   ruby jar_to_storage.rb > state.json                            # bridge
#   npx @playwright/mcp@latest --storage-state state.json          # browse authed
#
# Usage:
#   jar_to_storage.rb [--jar PATH] [--origin URL] [--out PATH]
#
#   --jar     cookie jar (default: $JAR or ./.hotwire/cookies.txt)
#   --origin  base URL used to fill in domain/secure/sameSite sanely
#             (default: $BASE_URL or http://localhost:3000)
#   --out     write to a file instead of stdout
#
# Notes:
# - Playwright requires a `sameSite` of Strict|Lax|None; we default to Lax.
# - Session cookies (no expiry) are emitted with expires:-1, which Playwright
#   treats as a session cookie — correct for a Rails _session cookie.

require "json"
require "uri"

jar     = ENV["JAR"] || "./.hotwire/cookies.txt"
origin  = ENV["BASE_URL"] || "http://localhost:3000"
out     = nil

args = ARGV.dup
until args.empty?
  case args.shift
  when "--jar"    then jar = args.shift
  when "--origin" then origin = args.shift
  when "--out"    then out = args.shift
  when "-h", "--help"
    puts File.read(__FILE__)[/\A#!.*?\n(.*?)\n\n/m, 1].to_s.gsub(/^# ?/, "")
    exit 0
  else
    warn "unknown arg"; exit 2
  end
end

abort "cookie jar not found: #{jar} (run flow.sh / req.sh first to create it)" unless File.exist?(jar)

uri    = URI(origin)
secure = uri.scheme == "https"

cookies = File.readlines(jar).filter_map do |line|
  # Netscape format: domain \t flag \t path \t secure \t expiry \t name \t value
  # httponly cookies may be prefixed with "#HttpOnly_"; keep them, drop other comments.
  http_only = line.start_with?("#HttpOnly_")
  clean = line.sub(/\A#HttpOnly_/, "")
  next if clean.start_with?("#") || clean.strip.empty?

  domain, _flag, path, csecure, expiry, name, value = clean.chomp.split("\t")
  next unless name && !name.empty?

  # Jars written by these scripts use the literal host (e.g. fragua.localhost)
  # as the domain and "0" expiry for session cookies.
  exp = expiry.to_i
  {
    "name"     => name,
    "value"    => value.to_s,
    "domain"   => (domain && !domain.empty? ? domain.sub(/\A\./, "") : uri.host),
    "path"     => (path && !path.empty? ? path : "/"),
    "expires"  => (exp.positive? ? exp : -1),
    "httpOnly" => http_only,
    "secure"   => (csecure == "TRUE") || secure,
    "sameSite" => "Lax"
  }
end

if cookies.empty?
  warn "warning: no cookies found in #{jar} — is the session authenticated?"
end

state = { "cookies" => cookies, "origins" => [] }
json  = JSON.pretty_generate(state)

if out
  File.write(out, json)
  warn "wrote #{cookies.size} cookie(s) to #{out}"
else
  puts json
end
