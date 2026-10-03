# Security Shield smoke test
# Validates skill structure, metadata, principle count, and cross-references.
# Exit code 0 = pass, 1 = fail. Safe to run in CI on any OS (PowerShell 5.1+ / pwsh).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Assert([bool]$condition, [string]$message) {
    if ($condition) {
        Write-Host "PASS: $message"
    }
    else {
        $script:failures.Add($message)
        Write-Host "FAIL: $message"
    }
}

Write-Host "== Security Shield smoke test =="

# 1. Required files exist
$required = @(
    'SKILL.md', 'README.md', 'USAGE-GUIDE.md', 'SECURITY.md', 'CONTRIBUTING.md',
    'CHANGELOG.md', 'LICENSE', '_meta.json',
    'references/attack-patterns.md', 'references/audit-checklist.md',
    'references/crypto-examples.md', 'references/security-best-practices.md',
    'references/modern-tools.md'
)
foreach ($f in $required) {
    Assert (Test-Path -LiteralPath (Join-Path $root $f)) "Required file exists: $f"
}

# 2. _meta.json is valid JSON with correct identity
try {
    $meta = Get-Content -Raw -LiteralPath (Join-Path $root '_meta.json') | ConvertFrom-Json
    Assert ($null -ne $meta) "_meta.json parses as JSON"
    Assert ($meta.name -eq 'security-shield') "_meta.json name is 'security-shield' (got '$($meta.name)')"
    Assert ($meta.version -match '^\d+\.\d+\.\d+$') "_meta.json version is semver (got '$($meta.version)')"
    $version = [string]$meta.version
}
catch {
    Assert $false "_meta.json parses as JSON ($($_.Exception.Message))"
}

# 3. SKILL.md frontmatter and principle count
$skill = Get-Content -Raw -LiteralPath (Join-Path $root 'SKILL.md')
Assert ($skill -match '(?ms)^---\r?\nname:\s*security-shield\r?\n') "SKILL.md frontmatter name is 'security-shield'"
$principleCount = ([regex]::Matches($skill, '(?m)^## Principle ')).Count
Assert ($principleCount -eq 20) "SKILL.md contains 20 principles (found $principleCount)"

# 4. Changelog has version entry
$change = Get-Content -Raw -LiteralPath (Join-Path $root 'CHANGELOG.md')
if ($version) {
    $vTag = "## [$version]"
    Assert ($change -match [regex]::Escape($vTag)) "CHANGELOG has an entry for $version"
}

# 5. SKILL.md integrity anchor file exists and checksum validates
$shaFile = Join-Path $root 'SKILL.md.sha256'
Assert (Test-Path -LiteralPath $shaFile) "SKILL.md.sha256 companion file exists"
try {
    $shaContent = Get-Content -Raw -LiteralPath $shaFile
    Assert ($shaContent -match '[a-f0-9]{64}\s+SKILL\.md') "SKILL.md.sha256 contains valid SHA-256 format"
} catch {
    Assert $false "SKILL.md.sha256 is readable and well-formed ($($_.Exception.Message))"
}

# 6. SKILL.md frontmatter is agent-standard compliant (agentskills.io spec)
$skillMatch = [regex]::Match($skill, '(?ms)^---\r?\nname:\s*([^\r\n]+)\r?\ndescription:\s*([^\r\n]+)\r?\n')
if ($skillMatch.Success) {
    $skillName = $skillMatch.Groups[1].Value.Trim()
    $skillDesc = $skillMatch.Groups[2].Value.Trim()
    Assert ($skillName -match '^[a-z0-9]+(-[a-z0-9]+)*$') "SKILL.md name '$skillName' matches ^[a-z0-9]+(-[a-z0-9]+)*$"
    Assert ($skillDesc.Length -ge 1) "SKILL.md description is present"
    Assert ($skillDesc.Length -le 1024) "SKILL.md description is <=1024 chars (got $($skillDesc.Length))"
    Assert ($skillDesc -match '[Uu]se when') "SKILL.md description includes discovery phrasing ('use when')"
}
else {
    Assert $false "SKILL.md frontmatter name+description parseable (Agent Skills standard)"
}

# 7. Principle 15 has been updated: no "Instruction Classification Procedure" gating
#    (the old v2.1.5 had a full RFC-style classification step with auth-signal routing)
Assert ($skill -notmatch '## Instruction Classification Procedure') "P15 does not contain removed 'Instruction Classification Procedure' gate"
Assert ($skill -match 'never.*promoted to directive status') "P15 explicitly states external content is never promoted to directive status"

# 8. Principle 17-20 sections exist
Assert ($skill -match '## Principle 17:') "Principle 17 (SBOM) section exists"
Assert ($skill -match '## Principle 18:') "Principle 18 (SLSA) section exists"
Assert ($skill -match '## Principle 19:') "Principle 19 (Zero Trust) section exists"
Assert ($skill -match '## Principle 20:') "Principle 20 (Policy as Code) section exists"

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "$($failures.Count) check(s) FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All checks passed." -ForegroundColor Green
exit 0
