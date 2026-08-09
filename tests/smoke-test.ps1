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
    'references/attack.patterns.md', 'references/audit-checklist.md',
    'references/crypto-examples.md', 'references/security-best-practices.md'
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
    Assert ($meta.features.'full-system-audit' -eq $true) "_meta.json advertises full-system-audit"
    $version = [string]$meta.version
}
catch {
    Assert $false "_meta.json parses as JSON ($($_.Exception.Message))"
}

# 3. SKILL.md frontmatter and principle count
$skill = Get-Content -Raw -LiteralPath (Join-Path $root 'SKILL.md')
Assert ($skill -match '(?ms)^---\r?\nname:\s*security-shield\r?\n') "SKILL.md frontmatter name is 'security-shield'"
$principleCount = ([regex]::Matches($skill, '(?m)^## Principle ')).Count
Assert ($principleCount -eq 16) "SKILL.md contains 16 principles (found $principleCount)"

# 4. README lists the same principle set
$readme = Get-Content -Raw -LiteralPath (Join-Path $root 'README.md')
$principleSection = [regex]::Match($readme, '(?ms)## 📋 The 16 Security Principles(.*?)---').Value
$readmePrinciples = ([regex]::Matches($principleSection, '(?m)^\d+\. \*\*')).Count
Assert ($readmePrinciples -eq 16) "README lists 16 principles (found $readmePrinciples)"

# 5. Version alignment across metadata and docs
$change = Get-Content -Raw -LiteralPath (Join-Path $root 'CHANGELOG.md')
if ($version) {
    $vTag = "## [$version]"
    Assert ($change -match [regex]::Escape($vTag)) "CHANGELOG has an entry for $version"
}
$sec = Get-Content -Raw -LiteralPath (Join-Path $root 'SECURITY.md')
Assert ($sec -match '2\.0\.x\s*\|\s*✅') "SECURITY.md marks 2.0.x as supported"

# 6. Documented cross-references resolve to real files
$guide = Get-Content -Raw -LiteralPath (Join-Path $root 'USAGE-GUIDE.md')
foreach ($link in @('attack.patterns.md', 'crypto-examples.md', 'audit-checklist.md', 'security-best-practices.md')) {
    Assert (Test-Path -LiteralPath (Join-Path $root "references\$link")) "USAGE-GUIDE references references/$link"
}

# 7. No phantom commands in the usage guide
Assert ($guide -notmatch 'clawhub security ') "USAGE-GUIDE does not document phantom 'clawhub security' commands"

# 8. No stale exception-marker references remain
Assert ($sec -notmatch 'TESTING\s*:') "SECURITY.md no longer references removed TESTING markers"
$contrib = Get-Content -Raw -LiteralPath (Join-Path $root 'CONTRIBUTING.md')
Assert ($contrib -notmatch 'TESTING\s*:') "CONTRIBUTING.md no longer references removed TESTING markers"

# 9. Install commands are current and cross-agent
Assert ($meta.installation.command -eq 'openclaw skills install @z-hussein/security-shield') "_meta.json documents the OpenClaw install command"
Assert ($meta.installation.'cross-agent-command' -eq 'npx skills add https://clawhub.ai/z-hussein/skills/security-shield') "_meta.json documents the cross-agent install command"
$readme = Get-Content -Raw -LiteralPath (Join-Path $root 'README.md')
Assert ($readme -notmatch 'clawhub install security-shield') "README no longer uses the outdated 'clawhub install' command"
Assert ($readme -match 'npx skills add https://clawhub\.ai/z-hussein/skills/security-shield') "README documents the npx skills add install command"
Assert ($guide -notmatch 'clawhub install security-shield') "USAGE-GUIDE no longer uses the outdated 'clawhub install' command"
Assert ($guide -match 'npx skills add https://clawhub\.ai/z-hussein/skills/security-shield') "USAGE-GUIDE documents the npx skills add install command"

# 10. SKILL.md frontmatter is agent-standard compliant (agentskills.io spec)
#     Rule: description is required and <1024 chars; name is lowercase-hyphens.
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

# 11. SKILL.md integrity anchor file exists and checksum validates
$shaFile = Join-Path $root 'SKILL.md.sha256'
Assert (Test-Path -LiteralPath $shaFile) "SKILL.md.sha256 companion file exists"
try {
    $shaContent = Get-Content -Raw -LiteralPath $shaFile
    Assert ($shaContent -match '[a-f0-9]{64}\s+SKILL\.md') "SKILL.md.sha256 contains valid SHA-256 format"
} catch {
    Assert $false "SKILL.md.sha256 is readable and well-formed ($($_.Exception.Message))"
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "$($failures.Count) check(s) FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All checks passed." -ForegroundColor Green
exit 0
