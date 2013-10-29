json.array!(@rulesets) do |ruleset|
  json.extract! ruleset, :map_id, :playercount
  json.url ruleset_url(ruleset, format: :json)
end
