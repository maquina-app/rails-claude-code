#!/usr/bin/env ruby
# frozen_string_literal: true
#
# storage_to_jar.rb — reverse bridge: Playwright session -> curl cookie jar.
#
# Use when Playwright does a JS-heavy login through the real UI (e.g. an OAuth
# popup or a Stimulus-driven form curl can't replay), then you want to drop back
# to the fast curl tools + log reading for the rest of the work.
#
#   # in Playwright: await context.storageState({ path: 'state.json' })
#   ruby storage_to_jar.rb --in state.json            # writes ./.hotwire/cookies.txt
#   req.sh GET /dashboard                             # now authenticated
#
# Usage:
#   storage_to_jar.rb [--in PATH] [--jar PATH]
#     --in   Playwright storageState JSON (default: state.json)
#     --jar  output cookie jar (default: $JAR or ./.hotwire/cookies.txt)

require "json"

infile = "state.json"
jar    = ENV["JAR"] || "./.hotwire/cookies.txt"

args = ARGV.dup
until args.empty?
  case args.shift
  when "--in"  then infile = args.shift
  when "--jar" then jar = args.shift
  when "-h", "--help" then puts File.read(__FILE__)[/\A#!.*?\n(.*?)\n\n/m, 1].to_s.gsub(/^# ?/, ""); exit 0
  else warn "unknown arg"; exit 2
  end
end

abort "storageState not found: #{infile}" unless File.exist?(infile)
state = JSON.parse(File.read(infile))
cookies = state["cookies"] || []

require "fileutils"
FileUtils.mkdir_p(File.dirname(jar))

lines = ["# Netscape HTTP Cookie File", "# Written by storage_to_jar.rb"]
cookies.each do |c|
  domain = c["httpOnly"] ? "#HttpOnly_#{c['domain']}" : c["domain"].to_s
  expiry = c["expires"].to_i
  expiry = 0 if expiry.negative? # session cookie
  lines << [
    domain, "FALSE", (c["path"] || "/"),
    (c["secure"] ? "TRUE" : "FALSE"), expiry.to_s,
    c["name"], c["value"].to_s
  ].join("\t")
end

File.write(jar, lines.join("\n") + "\n")
warn "wrote #{cookies.size} cookie(s) to #{jar}"
