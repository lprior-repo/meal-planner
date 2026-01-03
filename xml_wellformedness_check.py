#!/usr/bin/env python3
"""
XML Well-formedness and Special Character Validation
"""

import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict
import html

class XMLWellFormednessValidator:
    def __init__(self, docs_dir: str):
        self.docs_dir = Path(docs_dir)
        self.results = {
            'total': 0,
            'well_formed': 0,
            'malformed': 0,
            'special_char_issues': [],
            'parsing_errors': []
        }

    def extract_metadata(self, content: str):
        """Extract metadata XML string."""
        pattern = r'<!--\s*\n(<doc_metadata>.*?</doc_metadata>)\s*\n-->'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            return match.group(1)
        return None

    def check_special_chars(self, xml_str: str, filename: str):
        """Check for unescaped special characters."""
        issues = []

        # Check for common problematic patterns
        # Unescaped & not part of entity
        unescaped_amp = re.findall(r'&(?!amp;|lt;|gt;|quot;|apos;|#\d+;|#x[0-9a-fA-F]+;)', xml_str)
        if unescaped_amp:
            issues.append(f"Unescaped & character: {unescaped_amp[:3]}")

        # Unescaped < or > outside tags
        # This is complex to detect accurately, so we'll rely on XML parser

        # Check for valid UTF-8
        try:
            xml_str.encode('utf-8')
        except UnicodeEncodeError as e:
            issues.append(f"Invalid UTF-8 encoding: {e}")

        return issues

    def validate_document(self, filepath: Path):
        """Validate XML well-formedness of a document."""
        self.results['total'] += 1

        try:
            content = filepath.read_text(encoding='utf-8')
        except Exception as e:
            self.results['parsing_errors'].append({
                'file': filepath.name,
                'error': f"Failed to read file: {e}"
            })
            return

        xml_str = self.extract_metadata(content)
        if not xml_str:
            self.results['parsing_errors'].append({
                'file': filepath.name,
                'error': "No metadata block found"
            })
            return

        # Check special characters
        char_issues = self.check_special_chars(xml_str, filepath.name)
        if char_issues:
            self.results['special_char_issues'].append({
                'file': filepath.name,
                'issues': char_issues
            })

        # Parse XML
        xml_with_decl = f'<?xml version="1.0" encoding="UTF-8"?>\n{xml_str}'
        try:
            root = ET.fromstring(xml_with_decl)
            self.results['well_formed'] += 1

            # Additional checks on parsed tree
            # Check for empty elements that should have content
            for elem in root.iter():
                if elem.tag in ['title', 'description', 'type', 'category', 'language']:
                    if elem.text is None or not elem.text.strip():
                        self.results['special_char_issues'].append({
                            'file': filepath.name,
                            'issues': [f"Empty required element: <{elem.tag}>"]
                        })

        except ET.ParseError as e:
            self.results['malformed'] += 1
            self.results['parsing_errors'].append({
                'file': filepath.name,
                'error': f"XML Parse Error: {e}",
                'xml_preview': xml_str[:200]
            })

    def run(self):
        """Run validation on all documents."""
        all_files = sorted(Path(self.docs_dir).glob("*.md"))

        print(f"Checking XML well-formedness for {len(all_files)} documents...\n")

        for filepath in all_files:
            self.validate_document(filepath)

        self.print_report()

    def print_report(self):
        """Print validation report."""
        print("="*80)
        print("XML WELL-FORMEDNESS VALIDATION REPORT")
        print("="*80)

        total = self.results['total']
        well_formed = self.results['well_formed']
        malformed = self.results['malformed']

        print(f"\nTotal Documents:     {total}")
        print(f"Well-formed XML:     {well_formed} ({well_formed/total*100:.1f}%)")
        print(f"Malformed XML:       {malformed} ({malformed/total*100 if total > 0 else 0:.1f}%)")

        if self.results['parsing_errors']:
            print(f"\n{'='*80}")
            print(f"PARSING ERRORS: {len(self.results['parsing_errors'])}")
            print(f"{'='*80}")
            for item in self.results['parsing_errors'][:20]:
                print(f"\n{item['file']}:")
                print(f"  Error: {item['error']}")
                if 'xml_preview' in item:
                    print(f"  Preview: {item['xml_preview'][:100]}...")

        if self.results['special_char_issues']:
            print(f"\n{'='*80}")
            print(f"SPECIAL CHARACTER ISSUES: {len(self.results['special_char_issues'])}")
            print(f"{'='*80}")
            for item in self.results['special_char_issues'][:20]:
                print(f"\n{item['file']}:")
                for issue in item['issues']:
                    print(f"  - {issue}")

        if not self.results['parsing_errors'] and not self.results['special_char_issues']:
            print("\n✓ All XML metadata blocks are well-formed!")
            print("✓ No special character escaping issues detected!")

if __name__ == "__main__":
    validator = XMLWellFormednessValidator("/home/lewis/src/meal-planner/docs/_indexed/docs")
    validator.run()
