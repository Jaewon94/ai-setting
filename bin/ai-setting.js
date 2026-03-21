#!/usr/bin/env node
'use strict';

const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const repoRoot = path.resolve(__dirname, '..');
const script = path.join(repoRoot, 'init.sh');
const args = process.argv.slice(2);

function findBash() {
  if (os.platform() !== 'win32') return 'bash';

  const candidates = [
    process.env.PROGRAMFILES && path.join(process.env.PROGRAMFILES, 'Git', 'bin', 'bash.exe'),
    'C:\\Program Files\\Git\\bin\\bash.exe',
    'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Programs', 'Git', 'bin', 'bash.exe'),
  ].filter(Boolean);

  for (const c of candidates) {
    try {
      fs.accessSync(c, fs.constants.X_OK);
      return c;
    } catch {}
  }

  return 'bash';
}

try {
  execFileSync(findBash(), [script, ...args], {
    stdio: 'inherit',
    env: { ...process.env, AI_SETTING_USAGE_NAME: 'ai-setting' },
  });
} catch (err) {
  if (err.status != null) process.exit(err.status);
  console.error(
    'Error: bash not found. Install Git for Windows (https://git-scm.com) or WSL.'
  );
  process.exit(1);
}
