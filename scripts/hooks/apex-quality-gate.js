#!/usr/bin/env node
'use strict';

/**
 * apex-quality-gate.js — Consolidated Apex quality gate hook
 *
 * Replaces: apex-lint.js + post-edit-governor-scan.js + post-edit-security-scan.js
 *
 * Profile-aware via CSIQ_HOOK_PROFILE env var:
 *   minimal  — SOQL/DML in loops only (fastest)
 *   standard — + sharing keyword + hardcoded IDs + security checks (default)
 *   strict   — all above + unbounded collections + enqueue in loops + callouts in loops
 *
 * Individual checks can be disabled:
 *   CSIQ_DISABLED_HOOKS="no-soql-in-loop,no-hardcoded-secrets"
 */

const fs = require('fs');
const path = require('path');
const { formatFindings, formatSummary } = require('../lib/report-formatter');

// ── Input resolution ──────────────────────────────────────────────────────────
let fromStdinHook = false;
function getFilePath() {
  if (process.argv[2]) return process.argv[2];
  try {
    const stdin = fs.readFileSync('/dev/stdin', 'utf8');
    const data = JSON.parse(stdin);
    fromStdinHook = true;
    return (data.tool_input && (data.tool_input.file_path || data.tool_input.path)) || null;
  } catch (_) {
    return null;
  }
}

const filePath = getFilePath();
if (!filePath) {
  if (fromStdinHook) process.exit(0);
  console.error('Usage: apex-quality-gate.js <file>');
  process.exit(1);
}
if (fromStdinHook && !/\.(cls|trigger)$/i.test(filePath)) process.exit(0);
if (!fs.existsSync(filePath)) {
  if (fromStdinHook) process.exit(0);
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

// ── Profile & disabled checks ─────────────────────────────────────────────────
const PROFILE = (process.env.CSIQ_HOOK_PROFILE || 'standard').toLowerCase();
const DISABLED = new Set((process.env.CSIQ_DISABLED_HOOKS || '').split(',').map(s => s.trim()).filter(Boolean));

function isEnabled(rule, minProfile = 'minimal') {
  if (DISABLED.has(rule)) return false;
  const profiles = { minimal: 0, standard: 1, strict: 2 };
  const current = profiles[PROFILE] ?? 1;
  const required = profiles[minProfile] ?? 0;
  return current >= required;
}

// ── File content ──────────────────────────────────────────────────────────────
const content = fs.readFileSync(filePath, 'utf8');
const lines = content.split('\n');
const findings = [];
const isTestClass = /Test\.cls$/i.test(filePath) || /@isTest/i.test(content);

// ── Check 1: SOQL/DML/Callouts in loops (minimal+) ───────────────────────────
{
  let inLoop = false;
  let loopDepth = 0;
  let braceDepth = 0;
  const loopStartDepths = [];
  const dmlKeywords = ['insert', 'update', 'delete', 'upsert', 'undelete', 'merge'];

  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    const lineNum = idx + 1;

    if (/^\s*(for|while)\s*\(/.test(trimmed) || /^\s*do\s*\{/.test(trimmed)) {
      loopStartDepths.push(braceDepth);
      inLoop = true;
      loopDepth++;
    }

    for (const ch of trimmed) {
      if (ch === '{') { braceDepth++; }
      if (ch === '}') {
        braceDepth--;
        while (loopStartDepths.length > 0 && braceDepth <= loopStartDepths[loopStartDepths.length - 1]) {
          loopStartDepths.pop();
          loopDepth--;
        }
        inLoop = loopDepth > 0;
      }
    }

    if (inLoop) {
      // SOQL in loop
      if (isEnabled('no-soql-in-loop') && (/\[SELECT\b/i.test(trimmed) || /Database\.query\s*\(/i.test(trimmed))) {
        findings.push({
          file: filePath, line: lineNum, severity: 'CRITICAL',
          message: 'SOQL query inside a loop. Move query before the loop and use a Map/collection.',
          rule: 'no-soql-in-loop'
        });
      }

      // DML in loop
      if (isEnabled('no-dml-in-loop')) {
        for (const kw of dmlKeywords) {
          if (new RegExp(`^\\s*${kw}\\s+`, 'i').test(trimmed) ||
              new RegExp(`Database\\.${kw}\\s*\\(`, 'i').test(trimmed)) {
            findings.push({
              file: filePath, line: lineNum, severity: 'CRITICAL',
              message: `DML "${kw}" inside a loop. Collect records and perform DML after the loop.`,
              rule: 'no-dml-in-loop'
            });
          }
        }
      }

      // Callout in loop (strict+)
      if (isEnabled('no-callout-in-loop', 'strict') && /Http\.send\s*\(|\.send\s*\(\s*req/i.test(trimmed)) {
        findings.push({
          file: filePath, line: lineNum, severity: 'CRITICAL',
          message: 'HTTP callout inside a loop. Risk of hitting callout governor limits.',
          rule: 'no-callout-in-loop'
        });
      }

      // System.enqueueJob in loop (strict+)
      if (isEnabled('no-enqueue-in-loop', 'strict') && /System\.enqueueJob\s*\(/i.test(trimmed)) {
        findings.push({
          file: filePath, line: lineNum, severity: 'HIGH',
          message: 'System.enqueueJob() inside a loop. Risk of hitting queueable limits (max 50 per transaction).',
          rule: 'no-enqueue-in-loop'
        });
      }
    }
  });
}

// ── Check 2: Missing sharing keyword (standard+) ──────────────────────────────
if (isEnabled('require-sharing-keyword', 'standard')) {
  const classRegex = /\b(public|private|global)\s+(virtual\s+|abstract\s+|with\s+sharing\s+|without\s+sharing\s+|inherited\s+sharing\s+)*class\b/gi;
  let match;
  while ((match = classRegex.exec(content)) !== null) {
    const classDecl = match[0];
    if (!/with\s+sharing|without\s+sharing|inherited\s+sharing/i.test(classDecl)) {
      const lineNum = content.substring(0, match.index).split('\n').length;
      findings.push({
        file: filePath, line: lineNum, severity: 'HIGH',
        message: 'Class missing sharing keyword. Add "with sharing" (default), "without sharing" (with comment), or "inherited sharing".',
        rule: 'require-sharing-keyword'
      });
    }
  }
}

// ── Check 3: Security checks (standard+) ─────────────────────────────────────
lines.forEach((line, idx) => {
  const trimmed = line.trim();
  const lineNum = idx + 1;

  // without sharing without justification
  if (isEnabled('without-sharing-justification', 'standard') && /without\s+sharing/i.test(trimmed)) {
    const prevLine = idx > 0 ? lines[idx - 1].trim() : '';
    const hasJustification = /\/\//.test(trimmed) || /\/\//.test(prevLine) || /\/\*/.test(prevLine);
    if (!hasJustification) {
      findings.push({
        file: filePath, line: lineNum, severity: 'HIGH',
        message: '"without sharing" used without justification comment. Add a comment explaining why.',
        rule: 'without-sharing-justification'
      });
    }
  }

  // SOQL injection via string concatenation
  if (isEnabled('no-soql-injection', 'standard')) {
    if (/Database\.query\s*\(/i.test(trimmed) && (/\+\s*['"]/.test(trimmed) || /['"]\s*\+/.test(trimmed))) {
      findings.push({
        file: filePath, line: lineNum, severity: 'CRITICAL',
        message: 'Dynamic SOQL with string concatenation. Use bind variables or Database.queryWithBinds().',
        rule: 'no-soql-injection'
      });
    }
    if (/['"]SELECT\s+/i.test(trimmed) && /\+/.test(trimmed)) {
      findings.push({
        file: filePath, line: lineNum, severity: 'CRITICAL',
        message: 'SOQL string built with concatenation. Use bind variables to prevent injection.',
        rule: 'no-soql-injection'
      });
    }
  }

  // Hardcoded credentials
  if (isEnabled('no-hardcoded-secrets', 'standard') && !isTestClass) {
    if (/(?:password|secret|token|apikey|api_key)\s*=\s*['"]/i.test(trimmed)) {
      findings.push({
        file: filePath, line: lineNum, severity: 'CRITICAL',
        message: 'Possible hardcoded credential. Use Named Credentials or Protected Custom Metadata.',
        rule: 'no-hardcoded-secrets'
      });
    }
  }

  // Hardcoded Salesforce IDs
  if (isEnabled('no-hardcoded-ids', 'standard') && !isTestClass) {
    const idMatch = /['"]([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})['"]/.exec(trimmed);
    if (idMatch) {
      const sfIdPrefixes = ['001', '003', '005', '006', '00D', '00G', '00e', '012', '01I', '01p', '01q', '0DM'];
      if (sfIdPrefixes.some(p => idMatch[1].startsWith(p))) {
        findings.push({
          file: filePath, line: lineNum, severity: 'HIGH',
          message: `Possible hardcoded Salesforce ID: "${idMatch[1]}". Use Custom Metadata or Schema API instead.`,
          rule: 'no-hardcoded-ids'
        });
      }
    }
  }

  // Hardcoded URLs
  if (isEnabled('no-hardcoded-urls', 'standard') && !isTestClass) {
    if (/https?:\/\/[^\s'"]+/i.test(trimmed) && !/\/\/\s/.test(trimmed.split('http')[0])) {
      findings.push({
        file: filePath, line: lineNum, severity: 'MEDIUM',
        message: 'Hardcoded URL detected. Use Named Credentials or Custom Metadata for endpoint configuration.',
        rule: 'no-hardcoded-urls'
      });
    }
  }
});

// ── Check 4: CRUD/FLS enforcement (standard+) ─────────────────────────────────
if (isEnabled('require-crud-fls', 'standard') && !isTestClass) {
  const hasSOQL = /\[SELECT\b/i.test(content) || /Database\.query/i.test(content);
  const hasEnforcement = /WITH\s+SECURITY_ENFORCED/i.test(content) ||
                          /WITH\s+USER_MODE/i.test(content) ||
                          /Security\.stripInaccessible/i.test(content) ||
                          /stripInaccessible/i.test(content);
  if (hasSOQL && !hasEnforcement) {
    findings.push({
      file: filePath, line: 1, severity: 'HIGH',
      message: 'Class queries data but has no CRUD/FLS enforcement. Add WITH USER_MODE, WITH SECURITY_ENFORCED, or Security.stripInaccessible().',
      rule: 'require-crud-fls'
    });
  }
}

// ── Output ────────────────────────────────────────────────────────────────────
if (findings.length > 0) {
  const label = `[${PROFILE.toUpperCase()} profile]`;
  console.log(formatFindings(findings));
  if (typeof formatSummary === 'function') {
    console.log('\n' + formatSummary(findings));
  }
  console.log(`\n${label} ${path.basename(filePath)}: ${findings.length} issue(s) found.`);
  const hasCritical = findings.some(f => f.severity === 'CRITICAL');
  process.exit(hasCritical ? 1 : 0);
} else {
  console.log(`\u2705 [${PROFILE.toUpperCase()}] ${path.basename(filePath)}: All Apex quality checks passed.`);
}
