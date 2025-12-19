/**
 * Markdown formatters for different documentation styles
 */

/**
 * Format API reference documentation
 */
export function formatApiReference(content: string, metadata: Record<string, unknown>): string {
  const header = `---
title: ${metadata.title || 'API Reference'}
scraped: ${metadata.scrapedAt || new Date().toISOString()}
---

`;
  return header + content;
}

/**
 * Format guide/tutorial documentation
 */
export function formatGuide(content: string, metadata: Record<string, unknown>): string {
  const header = `# ${metadata.title || 'Guide'}

> Scraped from: ${metadata.url || 'Unknown source'}
> Date: ${metadata.scrapedAt || new Date().toISOString()}

---

`;
  return header + content;
}

/**
 * Add table of contents to markdown
 */
export function addTableOfContents(markdown: string): string {
  const headers: string[] = [];
  const lines = markdown.split('\n');

  // Extract headers
  lines.forEach((line) => {
    const match = line.match(/^(#{1,6})\s+(.+)$/);
    if (match) {
      const level = match[1].length;
      const title = match[2];
      const anchor = title
        .toLowerCase()
        .replace(/[^\w\s-]/g, '')
        .replace(/\s+/g, '-');

      const indent = '  '.repeat(level - 1);
      headers.push(`${indent}- [${title}](#${anchor})`);
    }
  });

  if (headers.length === 0) {
    return markdown;
  }

  const toc = `## Table of Contents

${headers.join('\n')}

---

`;

  return toc + markdown;
}
