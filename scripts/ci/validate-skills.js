#!/usr/bin/env node
'use strict';

/**
 * validate-skills.js
 *
 * The skills system was removed in v2.0. Skill content is now baked directly
 * into the domain commands that use it (apex-class, trigger, lwc, flow, etc.).
 *
 * This validator is kept as a no-op pass to avoid breaking the test pipeline.
 */

console.log('Skills system removed — domain commands include standards inline.\n');
console.log('Results: 0 skills to validate (skills system removed in v2.0).');
