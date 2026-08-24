# Renders `genai-etk eval result list --output json` into a human-readable markdown summary.
# Usage: jq -r --slurpfile cfg scorer-config.json -f format-results.jq results.json
($cfg[0] // {}) as $cfg0
| [
    .testResults[]
    | . as $tr
    | (
        $tr.scores
        | to_entries
        | map(
            . as $entry
            | ($entry.key | split(".")) as $parts
            | ($parts[0]) as $evaluator
            | ($parts[1:] | join(".")) as $scoreName
            | ($cfg0[$evaluator].scores[$scoreName].config.minimumPassingScore) as $threshold
            | (
                if $threshold != null then
                  if $entry.value.value >= $threshold then "✅ PASS" else "❌ FAIL" end
                  + " — score **\($entry.value.value)** (threshold \($threshold))"
                else
                  "score **\($entry.value.value)**"
                end
              ) as $verdictLine
            | "**`\($entry.key)`** — \($verdictLine)\n\n\($entry.value.reason // "")"
              + (
                  if ($entry.value.context.metadata.scores // null) != null then
                    "\n\n| Sub-check | Result |\n| --- | --- |\n"
                    + (
                        $entry.value.context.metadata.scores
                        | map("| `\(.name)` | " + (if .score >= 1 then "✅ \(.score)" else "❌ \(.score)" end) + " |")
                        | join("\n")
                      )
                  else "" end
                )
              + (
                  if (($entry.value.context.metadata.issues // []) | length) > 0 then
                    "\n\n**Issues:**\n"
                    + ($entry.value.context.metadata.issues | map("- " + .) | join("\n"))
                  else "" end
                )
          )
        | join("\n\n")
      ) as $scoreBlocks
    | "### Result: \($tr.input)\n\n- Result ID: `\($tr.resultId)`\n\n\($scoreBlocks)"
  ]
  | join("\n\n---\n\n")
