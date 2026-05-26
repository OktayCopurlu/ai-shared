#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

async function loadAjv() {
  try {
    const module = await import('ajv/dist/2020.js');
    return module.default;
  } catch (error) {
    console.error('JSON Schema validation requires the local dev dependency `ajv`.');
    console.error('Run: npm install --prefix experiment/delivery-pipeline');
    console.error(`Original error: ${error.message}`);
    process.exit(2);
  }
}

async function readJson(filePath) {
  try {
    return JSON.parse(await readFile(filePath, 'utf8'));
  } catch (error) {
    console.error(`Invalid JSON in ${filePath}: ${error.message}`);
    process.exit(1);
  }
}

const [, , schemaPath, dataPath] = process.argv;

if (!schemaPath || !dataPath) {
  console.error('Usage: validate-schema.mjs <schema.json> <data.json>');
  process.exit(2);
}

const Ajv2020 = await loadAjv();
const ajv = new Ajv2020({ allErrors: true, strict: false });
const schema = await readJson(schemaPath);
const data = await readJson(dataPath);
const validate = ajv.compile(schema);

if (!validate(data)) {
  console.error(`Schema validation failed for ${dataPath}`);
  for (const error of validate.errors ?? []) {
    const instancePath = error.instancePath || '/';
    console.error(`- ${instancePath} ${error.message}`);
  }
  process.exit(1);
}

console.log(`Schema validation passed: ${path.relative(process.cwd(), dataPath)}`);
