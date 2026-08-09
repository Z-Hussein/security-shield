# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.1.x   | ✅ Yes    |
| 2.0.x   | ❌ No     |
| 1.2.x   | ❌ No     |
| 1.1.x   | ❌ No     |
| 1.0.x   | ❌ No     |

## Reporting a Vulnerability

Security Shield is a security skill for OpenClaw agents. We take security issues seriously.

**Please DO NOT open a public GitHub issue for security vulnerabilities.**

Instead, report privately via:

1. **GitHub Private Vulnerability Reporting**: Go to [Security Advisories](../../security/advisories/new) and click "Report a vulnerability"
2. **Or email**: Create a GitHub issue with `[SECURITY]` prefix and we'll reach out privately

## What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

| Phase | Timeline |
|-------|----------|
| Acknowledgment | Within 48 hours |
| Initial Assessment | Within 7 days |
| Fix & Release | Within 30 days (critical) or 90 days (standard) |
| Public Disclosure | After fix is released |

## Security Principles

This skill follows these security practices:

1. **No pattern strings** - We use abstract descriptions, not specific strings that could be targeted
2. **Defense in depth** - Multiple overlapping protections
3. **Least privilege** - The skill only guides behavior, never executes commands
4. **Transparency** - All security decisions are explained to the user

## Known Limitations

- Security Shield guides agent behavior but cannot override compromised agent instructions
- The skill does not scan other skills for malware (use Skill Vetter for that)
- Security events are recorded via threat-handling rules in SKILL.md: events are written to memory/YYYY-MM-DD.md (event metadata only - never raw payloads). Quarantined files go to $HOME/.security-shield/quarantine/ (requires user approval first). The skill does NOT write to host system logs (syslog, journald, etc.); all event recording is within the agent's own workspace.
- During an explicitly requested full-system check, the agent may inspect local state within the agreed scope (see USAGE-GUIDE.md)

## Related Resources

- [OpenClaw Security Best Practices](https://docs.openclaw.com/security)
- [ClawHub Security Guidelines](https://clawhub.ai/security)
- [Skill Vetter](https://clawhub.ai/spclaudehome/skills/skill-vetter) - Scan skills before installation
