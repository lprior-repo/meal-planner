/**
 * File system utilities for saving scraped content
 */

import { writeFile, mkdir } from 'fs/promises';
import { dirname, join } from 'path';

/**
 * Save content to a file, creating directories as needed
 */
export async function saveToFile(filepath: string, content: string): Promise<void> {
  const dir = dirname(filepath);

  // Ensure directory exists
  await mkdir(dir, { recursive: true });

  // Write file
  await writeFile(filepath, content, 'utf-8');
}

/**
 * Generate a safe filename from a URL or title
 */
export function sanitizeFilename(name: string): string {
  return (
    name
      // Replace invalid filename characters
      .replace(/[<>:"/\\|?*]/g, '-')
      // Replace spaces with hyphens
      .replace(/\s+/g, '-')
      // Remove multiple consecutive hyphens
      .replace(/-+/g, '-')
      // Remove leading/trailing hyphens
      .replace(/^-|-$/g, '')
      // Lowercase
      .toLowerCase()
  );
}

/**
 * Create output path from base directory and filename
 */
export function createOutputPath(baseDir: string, filename: string): string {
  const safeName = sanitizeFilename(filename);
  return join(baseDir, `${safeName}.md`);
}
