'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const SKILLS_DIR = path.resolve(__dirname, '..', '..', 'skills');

describe('Skill directory validation', () => {
  it('should have no skill subdirectories — skills system removed in v2.0', () => {
    if (!fs.existsSync(SKILLS_DIR)) {
      // Directory doesn't exist at all — that's fine
      return;
    }
    // If directory exists, it should have no skill subdirectories
    const skillDirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);
    assert.strictEqual(skillDirs.length, 0, `Expected no skill directories, found: ${skillDirs.join(', ')}`);
  });

  it('should use lowercase-hyphen naming for directories', () => {
    if (!fs.existsSync(SKILLS_DIR)) return;
    const skillDirs = fs.readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);
    for (const dir of skillDirs) {
      assert.match(dir, /^[a-z][a-z0-9-]*$/, `Skill dir "${dir}" must be lowercase with hyphens`);
    }
  });
});
