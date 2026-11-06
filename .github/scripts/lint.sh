#!/usr/bin/env bash
# Lint the workflows, the test scripts, and the Bash bodies in action.yml.
#
# Usage: lint.sh
#
# Needs actionlint, shellcheck, and yq (mikefarah yq v4) on PATH. The
# development shell has all three: nix develop --command .github/scripts/lint.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
status=0

echo "actionlint: .github/workflows"
actionlint || status=1

echo "shellcheck: .github/scripts/*.sh"
shellcheck .github/scripts/*.sh || status=1

# The shellcheck tool cannot read action.yml, so write each step body to a
# file and check that. The substitution must not cause a finding of its own:
# - Each ${{ ... }} expression becomes ${GHA_EXPR}. A literal word would
#   cause SC2050 (constant expression) and SC2170 (invalid number for -gt).
#   The variable causes SC2086 only where an expression is an unquoted
#   command argument, and action.yml has none, so the substitution
#   needs no exclusion.
# - The second line exports the names in the step env map, so that they
#   do not count as unassigned (SC2153).
# Each finding names its line in action.yml. The column counts from the
# indentation of the step body.
work="$(mktemp --directory)"
trap 'rm -rf "${work}"' EXIT
steps="$(yq '.runs.steps | length' action.yml)"
for ((i = 0; i < steps; i++)); do
  step=".runs.steps[${i}]"
  body_path="${step} | (.run // .with.\"post-run\")"
  if [[ "$(yq "${body_path} | tag" action.yml)" != "!!str" ]]; then
    continue
  fi
  name="$(yq "${step}.name" action.yml)"
  # The body starts on the line after the "run: |" indicator.
  first_line="$(($(yq "${body_path} | line" action.yml) + 1))"
  env_names="$(yq "${step}.env // {} | keys | .[]" action.yml | tr '\n' ' ')"
  script="${work}/step${i}.sh"
  {
    echo '#!/usr/bin/env bash'
    if [[ -n "${env_names}" ]]; then
      echo "export ${env_names}"
    else
      echo ':'
    fi
    # shellcheck disable=SC2016 # sed writes ${GHA_EXPR} as literal text
    yq "${body_path}" action.yml | sed -E 's/\$\{\{[^}]*\}\}/${GHA_EXPR}/g'
  } > "${script}"
  echo "shellcheck: action.yml step ${name}"
  # The exit status is 1 for findings, and above 1 when shellcheck fails.
  shellcheck_status=0
  shellcheck --shell=bash --format=gcc "${script}" > "${work}/findings" || shellcheck_status=$?
  if [[ "${shellcheck_status}" -gt 1 ]]; then
    echo "shellcheck failed with status ${shellcheck_status} on step ${name}"
    status=1
  fi
  awk -v script="${script}" -v first="${first_line}" -v name="${name}" '
    index($0, script ":") == 1 {
      rest = substr($0, length(script) + 2)
      split(rest, parts, ":")
      found = 1
      print "action.yml:" (parts[1] + first - 3) substr(rest, length(parts[1]) + 1) " (" name ")"
    }
    END { exit found }
  ' "${work}/findings" || status=1
done

exit "${status}"
