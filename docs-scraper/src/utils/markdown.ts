/**
 * Markdown conversion utilities
 */

import TurndownService from 'turndown';

/**
 * Create a configured Turndown service for HTML to Markdown conversion
 */
export function createMarkdownConverter(): TurndownService {
  const turndown = new TurndownService({
    headingStyle: 'atx',
    codeBlockStyle: 'fenced',
    bulletListMarker: '-',
    emDelimiter: '_',
  });

  // Custom rules can be added here
  turndown.addRule('strikethrough', {
    filter: ['del', 's', 'strike'],
    replacement: (content) => `~~${content}~~`,
  });

  return turndown;
}

/**
 * Convert HTML to Markdown
 */
export function htmlToMarkdown(html: string): string {
  const converter = createMarkdownConverter();
  return converter.turndown(html);
}

/**
 * Clean up markdown formatting
 */
export function cleanMarkdown(markdown: string): string {
  return (
    markdown
      // Remove excessive blank lines (more than 2)
      .replace(/\n{3,}/g, '\n\n')
      // Trim whitespace from end of lines
      .replace(/[ \t]+$/gm, '')
      // Ensure file ends with single newline
      .trim() + '\n'
  );
}
