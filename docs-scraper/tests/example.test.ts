/**
 * Example test file to verify test setup
 */

import { describe, it, expect } from 'vitest';
import { sanitizeFilename } from '../src/utils/file.js';
import { cleanMarkdown } from '../src/utils/markdown.js';

describe('File utilities', () => {
  it('should sanitize filenames correctly', () => {
    expect(sanitizeFilename('Hello World')).toBe('hello-world');
    expect(sanitizeFilename('API/Reference')).toBe('api-reference');
    expect(sanitizeFilename('Test: Example')).toBe('test-example');
  });

  it('should remove multiple hyphens', () => {
    expect(sanitizeFilename('Hello   World')).toBe('hello-world');
    expect(sanitizeFilename('Test---Example')).toBe('test-example');
  });
});

describe('Markdown utilities', () => {
  it('should remove excessive blank lines', () => {
    const input = 'Line 1\n\n\n\nLine 2';
    const expected = 'Line 1\n\nLine 2\n';
    expect(cleanMarkdown(input)).toBe(expected);
  });

  it('should trim trailing whitespace', () => {
    const input = 'Line 1   \nLine 2  ';
    const expected = 'Line 1\nLine 2\n';
    expect(cleanMarkdown(input)).toBe(expected);
  });

  it('should end with single newline', () => {
    const input = 'Content';
    expect(cleanMarkdown(input)).toBe('Content\n');
  });
});
