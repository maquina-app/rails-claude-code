#!/usr/bin/env ruby
# frozen_string_literal: true
#
# submit_form.rb — fetch a page, find a form, merge your fields into its
# hidden inputs (incl. the Rails authenticity_token), and submit it.
#
# This removes the #1 failure mode of driving Rails by hand: a forgotten or
# stale CSRF token. It reuses the same cookie jar as req.sh.
#
# Usage:
#   submit_form.rb <page_path> [form_selector] field=value field=value ...
#
#   page_path      path to GET the form from, e.g. /session/new
#   form_selector  optional CSS selector (default: first <form> on the page).
#                  e.g. "form#new_session" or "form[action='/session']"
#   field=value    one or more fields to set/override in the form
#
# Env: BASE_URL (default http://localhost:3000), JAR (default ./.hotwire/cookies.txt)
#
# Output: the submit response (status line, request id, turbo streams if any,
#         redirect target, short body excerpt) as readable text.
#
# Requires Nokogiri. Run via the project's bundle so it's on the load path:
#   bundle exec ruby scripts/submit_form.rb ...

require "net/http"
require "uri"

begin
  require "nokogiri"
rescue LoadError
  warn "Nokogiri not found. Run this through the project's bundle: " \
       "`bundle exec ruby scripts/submit_form.rb ...`"
  exit 3
end

BASE_URL = ENV.fetch("BASE_URL", "http://localhost:3000")
JAR      = ENV.fetch("JAR", "./.hotwire/cookies.txt")

uri = URI(BASE_URL)
unless %w[localhost 127.0.0.1 0.0.0.0 ::1].include?(uri.host) || uri.host.to_s.end_with?(".localhost")
  warn "REFUSED: BASE_URL host '#{uri.host}' is not local."
  exit 2
end

# kamal-proxy routes by Host header. If RESOLVE is set we still connect to a
# local IP but keep the real hostname on the connection so routing works on
# systems where *.localhost doesn't resolve. RESOLVE=1 -> 127.0.0.1.
RESOLVE_IP =
  if (r = ENV["RESOLVE"])
    r == "1" ? "127.0.0.1" : r
  end

page_path = ARGV.shift or abort "page_path required"
selector  = ARGV.first&.include?("=") ? nil : ARGV.shift
fields    = ARGV.each_with_object({}) do |arg, h|
  k, v = arg.split("=", 2)
  h[k] = v.to_s
end

# --- tiny Netscape cookie-jar reader/writer (compatible with curl -c/-b) ----
def load_cookies(jar, host)
  return "" unless File.exist?(jar)
  File.readlines(jar).filter_map do |line|
    next if line.start_with?("#") || line.strip.empty?
    domain, _flag, _path, _secure, _exp, name, value = line.chomp.split("\t")
    next unless domain && host.end_with?(domain.sub(/^\./, ""))
    "#{name}=#{value}"
  end.join("; ")
end

def merge_set_cookie(jar, host, set_cookie_headers)
  return if set_cookie_headers.empty?
  existing = File.exist?(jar) ? File.readlines(jar) : []
  set_cookie_headers.each do |sc|
    pair = sc.split(";").first.to_s.strip
    name = pair.split("=", 2).first
    value = pair.split("=", 2)[1].to_s
    existing.reject! { |l| l.split("\t")[5] == name }
    existing << ["#{host}", "FALSE", "/", "FALSE", "0", name, value].join("\t") + "\n"
  end
  File.write(jar, existing.join)
end

def http_for(uri)
  # Construct with the real hostname so the Host header is correct (kamal-proxy
  # routes by it). If RESOLVE_IP is set, override only the connection IP via
  # #ipaddr= — the Host header is unaffected.
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  if RESOLVE_IP && http.respond_to?(:ipaddr=)
    http.ipaddr = RESOLVE_IP
  end
  http
end

# --- 1. GET the page that holds the form ------------------------------------
get_uri = URI.join(BASE_URL, page_path)
get_req = Net::HTTP::Get.new(get_uri)
get_req["Cookie"] = load_cookies(JAR, get_uri.host)
get_req["Accept"] = "text/html"
get_res = http_for(get_uri).request(get_req)
merge_set_cookie(JAR, get_uri.host, get_res.get_fields("set-cookie") || [])

doc  = Nokogiri::HTML(get_res.body)
form = selector ? doc.at_css(selector) : doc.at_css("form")
abort "No form found (selector: #{selector || 'first form'})" unless form

action = form["action"].to_s
action = page_path if action.empty?
# Rails fakes PUT/PATCH/DELETE via a _method hidden field; honor it.
method = (form["method"] || "post").upcase

# --- 2. collect the form's own inputs, then override with user fields -------
data = {}
form.css("input[name], textarea[name], select[name]").each do |el|
  name = el["name"]
  next if name.nil? || name.empty?
  if el.name == "select"
    opt = el.at_css("option[selected]") || el.at_css("option")
    data[name] = opt&.[]("value").to_s
  else
    data[name] = el["value"].to_s
  end
end
data.merge!(fields)

token_present = data.key?("authenticity_token") && !data["authenticity_token"].empty?
warn "note: no authenticity_token found in form (CSRF may be disabled, or wrong form)" unless token_present

# --- 3. POST it -------------------------------------------------------------
post_uri = URI.join(BASE_URL, action)
post = Net::HTTP::Post.new(post_uri) # always POST; _method carries the real verb
post["Cookie"] = load_cookies(JAR, post_uri.host)
post["Accept"] = "text/vnd.turbo-stream.html, text/html"
post.set_form_data(data)

res = http_for(post_uri).request(post)
merge_set_cookie(JAR, post_uri.host, res.get_fields("set-cookie") || [])

# --- 4. report --------------------------------------------------------------
puts "POST #{post_uri.path}  (form method: #{method})"
puts "Status: #{res.code} #{res.message}"
puts "X-Request-Id: #{res['x-request-id']}" if res["x-request-id"]
puts "Location: #{res['location']}" if res["location"]

ctype = res["content-type"].to_s
if ctype.include?("turbo-stream")
  streams = Nokogiri::HTML(res.body).css("turbo-stream").map do |s|
    "  - #{s['action']} ##{s['target']}#{s['targets'] ? " (#{s['targets']})" : ''}"
  end
  puts "Turbo Streams:"
  puts streams.empty? ? "  (none parsed)" : streams.join("\n")
else
  excerpt = res.body.to_s.gsub(/\s+/, " ").strip[0, 600]
  puts "Body excerpt:"
  puts "  #{excerpt}"
end
