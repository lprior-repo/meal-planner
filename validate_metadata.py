#!/usr/bin/env python3
"""
XML Metadata Schema Validator for transformed documentation.
Validates all documents in docs/_indexed/docs/ for schema compliance.
"""

import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Optional
import json

class MetadataValidator:
    VALID_TYPES = {'reference', 'guide', 'tutorial'}
    VALID_CATEGORIES = {'windmill', 'api', 'recipes', 'build-tools', 'core', 'fatsecret', 'tandoor', 'moonrepo', 'general'}
    VALID_DIFFICULTIES = {'beginner', 'intermediate', 'advanced'}
    REQUIRED_FIELDS = [
        'type', 'category', 'title', 'description', 'created_at',
        'updated_at', 'language', 'difficulty_level', 'estimated_reading_time', 'tags'
    ]

    def __init__(self, docs_dir: str):
        self.docs_dir = Path(docs_dir)
        self.results = {
            'total_checked': 0,
            'passed': 0,
            'failed': 0,
            'by_system': defaultdict(lambda: {'total': 0, 'passed': 0, 'failed': 0, 'issues': []}),
            'critical_issues': [],
            'all_issues': []
        }

    def extract_xml_metadata(self, content: str) -> Optional[str]:
        """Extract XML metadata from HTML comment block."""
        # Pattern 1: <!-- METADATA ... -->
        pattern1 = r'<!--\s*METADATA\s*\n(.*?)\n-->'
        match = re.search(pattern1, content, re.DOTALL)
        if match:
            return match.group(1).strip()

        # Pattern 2: <!-- <doc_metadata>...</doc_metadata> -->
        pattern2 = r'<!--\s*\n(<doc_metadata>.*?</doc_metadata>)\s*\n-->'
        match = re.search(pattern2, content, re.DOTALL)
        if match:
            return match.group(1).strip()

        return None

    def parse_xml(self, xml_str: str) -> Optional[ET.Element]:
        """Parse XML string and return root element."""
        try:
            # Wrap in root element if needed
            if not xml_str.strip().startswith('<?xml'):
                xml_str = f'<?xml version="1.0" encoding="UTF-8"?>\n{xml_str}'
            root = ET.fromstring(xml_str)
            return root
        except ET.ParseError as e:
            return None

    def get_system_from_filename(self, filename: str) -> str:
        """Extract system category from filename."""
        name = Path(filename).stem
        if 'fatsecret' in name:
            return 'fatsecret'
        elif 'tandoor' in name:
            return 'tandoor'
        elif 'moon' in name or 'moonrepo' in name:
            return 'moonrepo'
        elif 'windmill' in name:
            return 'windmill'
        else:
            return 'general'

    def validate_document(self, filepath: Path) -> Tuple[bool, List[str]]:
        """Validate a single document and return (is_valid, issues)."""
        issues = []

        try:
            content = filepath.read_text(encoding='utf-8')
        except Exception as e:
            issues.append(f"ERROR: Cannot read file - {e}")
            return False, issues

        # Check 1: XML metadata block exists
        xml_str = self.extract_xml_metadata(content)
        if not xml_str:
            issues.append("CRITICAL: No XML metadata block found")
            return False, issues

        # Check 2: XML is well-formed
        root = self.parse_xml(xml_str)
        if root is None:
            issues.append("CRITICAL: XML parsing failed - malformed XML")
            return False, issues

        # Check 3: Required fields present
        for field in self.REQUIRED_FIELDS:
            elem = root.find(field)
            if elem is None:
                issues.append(f"CRITICAL: Missing required field '{field}'")

        # Check 4: Validate field values
        # Type validation
        type_elem = root.find('type')
        if type_elem is not None and type_elem.text:
            if type_elem.text.lower() not in self.VALID_TYPES:
                issues.append(f"ERROR: Invalid type '{type_elem.text}' - must be one of {self.VALID_TYPES}")

        # Category validation
        category_elem = root.find('category')
        if category_elem is not None and category_elem.text:
            if category_elem.text.lower() not in self.VALID_CATEGORIES:
                issues.append(f"WARNING: Unexpected category '{category_elem.text}'")

        # Difficulty validation
        difficulty_elem = root.find('difficulty_level')
        if difficulty_elem is not None and difficulty_elem.text:
            if difficulty_elem.text.lower() not in self.VALID_DIFFICULTIES:
                issues.append(f"ERROR: Invalid difficulty_level '{difficulty_elem.text}' - must be one of {self.VALID_DIFFICULTIES}")

        # Check 5: Estimated reading time calculation
        reading_time_elem = root.find('estimated_reading_time')
        if reading_time_elem is not None and reading_time_elem.text:
            try:
                reading_time = int(reading_time_elem.text)
                # Count words in content (excluding metadata)
                body = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
                word_count = len(re.findall(r'\b\w+\b', body))
                expected_time = max(1, word_count // 200)
                # Allow 20% variance
                if abs(reading_time - expected_time) > expected_time * 0.2:
                    issues.append(f"WARNING: Reading time {reading_time} min may be inaccurate (expected ~{expected_time} min for {word_count} words)")
            except ValueError:
                issues.append(f"ERROR: Invalid estimated_reading_time - must be integer")

        # Check 6: Sections structure
        sections_elem = root.find('sections')
        if sections_elem is not None:
            # Extract actual headings from document
            headings = re.findall(r'^(#{2,})\s+(.+)$', content, re.MULTILINE)
            section_items = sections_elem.findall('section')

            if len(section_items) != len(headings):
                issues.append(f"WARNING: Section count mismatch - {len(section_items)} in metadata vs {len(headings)} in document")

            # Validate section structure (sections use attributes, not child elements)
            for idx, section in enumerate(section_items):
                name_attr = section.get('name')
                level_attr = section.get('level')

                if name_attr is None:
                    issues.append(f"ERROR: Section {idx+1} missing 'name' attribute")
                if level_attr is None:
                    issues.append(f"ERROR: Section {idx+1} missing 'level' attribute")
                elif level_attr:
                    try:
                        level_num = int(level_attr)
                        if level_num < 2 or level_num > 6:
                            issues.append(f"ERROR: Section {idx+1} invalid level '{level_attr}' - must be 2-6")
                    except ValueError:
                        issues.append(f"ERROR: Section {idx+1} invalid level '{level_attr}' - must be integer")

        # Check 7: Dependencies structure
        dependencies_elem = root.find('dependencies')
        if dependencies_elem is not None:
            for dep in dependencies_elem.findall('dependency'):
                dep_type = dep.find('type')
                if dep_type is not None and dep_type.text:
                    valid_dep_types = {'feature', 'crate', 'library', 'service', 'api', 'tool'}
                    if dep_type.text.lower() not in valid_dep_types:
                        issues.append(f"WARNING: Unexpected dependency type '{dep_type.text}'")

        # Check 8: Tags present and valid (comma-separated string format)
        tags_elem = root.find('tags')
        if tags_elem is not None:
            tags_text = tags_elem.text
            if not tags_text or not tags_text.strip():
                issues.append("WARNING: No tags defined")
            else:
                tags_list = [t.strip() for t in tags_text.split(',')]
                if len(tags_list) == 0:
                    issues.append("WARNING: No tags defined")

        # Check 9: Features structure
        features_elem = root.find('features')
        if features_elem is not None:
            feature_items = features_elem.findall('feature')
            # Just validate structure exists
            for feature in feature_items:
                if not feature.text or not feature.text.strip():
                    issues.append("WARNING: Empty feature element")

        return len([i for i in issues if 'CRITICAL' in i or 'ERROR' in i]) == 0, issues

    def validate_sample(self, files: List[Path], sample_name: str = "sample") -> Dict:
        """Validate a sample of files."""
        print(f"\n{'='*80}")
        print(f"Validating {sample_name}: {len(files)} documents")
        print(f"{'='*80}\n")

        sample_results = {
            'total': len(files),
            'passed': 0,
            'failed': 0,
            'issues_by_file': {}
        }

        for filepath in files:
            is_valid, issues = self.validate_document(filepath)
            system = self.get_system_from_filename(filepath.name)

            self.results['total_checked'] += 1
            self.results['by_system'][system]['total'] += 1

            if is_valid:
                self.results['passed'] += 1
                self.results['by_system'][system]['passed'] += 1
                sample_results['passed'] += 1
                print(f"✓ {filepath.name}")
            else:
                self.results['failed'] += 1
                self.results['by_system'][system]['failed'] += 1
                sample_results['failed'] += 1
                print(f"✗ {filepath.name}")

                critical_issues = [i for i in issues if 'CRITICAL' in i]
                if critical_issues:
                    self.results['critical_issues'].append({
                        'file': str(filepath),
                        'issues': critical_issues
                    })

                for issue in issues:
                    print(f"  - {issue}")
                    self.results['by_system'][system]['issues'].append({
                        'file': filepath.name,
                        'issue': issue
                    })

            sample_results['issues_by_file'][str(filepath)] = issues

        pass_rate = (sample_results['passed'] / sample_results['total'] * 100) if sample_results['total'] > 0 else 0
        print(f"\nSample Results: {sample_results['passed']}/{sample_results['total']} passed ({pass_rate:.1f}%)")

        return sample_results

    def print_summary(self):
        """Print comprehensive validation summary."""
        print("\n" + "="*80)
        print("VALIDATION SUMMARY")
        print("="*80)

        total = self.results['total_checked']
        passed = self.results['passed']
        failed = self.results['failed']
        pass_rate = (passed / total * 100) if total > 0 else 0

        print(f"\nOverall Results:")
        print(f"  Total Documents: {total}")
        print(f"  Passed: {passed} ({pass_rate:.1f}%)")
        print(f"  Failed: {failed} ({100-pass_rate:.1f}%)")

        print(f"\nResults by System:")
        for system in sorted(self.results['by_system'].keys()):
            data = self.results['by_system'][system]
            sys_total = data['total']
            sys_passed = data['passed']
            sys_rate = (sys_passed / sys_total * 100) if sys_total > 0 else 0
            print(f"  {system.upper():12s}: {sys_passed:3d}/{sys_total:3d} passed ({sys_rate:5.1f}%)")

        if self.results['critical_issues']:
            print(f"\n{'='*80}")
            print(f"CRITICAL ISSUES FOUND: {len(self.results['critical_issues'])}")
            print(f"{'='*80}")
            for item in self.results['critical_issues'][:20]:  # Show first 20
                print(f"\n{item['file']}:")
                for issue in item['issues']:
                    print(f"  - {issue}")

            if len(self.results['critical_issues']) > 20:
                print(f"\n... and {len(self.results['critical_issues']) - 20} more files with critical issues")

        # Issue frequency analysis
        print(f"\n{'='*80}")
        print("ISSUE FREQUENCY ANALYSIS")
        print(f"{'='*80}")

        issue_counts = defaultdict(int)
        for system_data in self.results['by_system'].values():
            for issue_item in system_data['issues']:
                # Extract issue type
                issue = issue_item['issue']
                if 'Missing required field' in issue:
                    issue_counts['Missing required fields'] += 1
                elif 'XML parsing failed' in issue:
                    issue_counts['XML parsing errors'] += 1
                elif 'No XML metadata' in issue:
                    issue_counts['Missing metadata block'] += 1
                elif 'Invalid type' in issue:
                    issue_counts['Invalid type field'] += 1
                elif 'Invalid difficulty_level' in issue:
                    issue_counts['Invalid difficulty_level'] += 1
                elif 'Reading time' in issue and 'inaccurate' in issue:
                    issue_counts['Inaccurate reading time'] += 1
                elif 'Section' in issue:
                    issue_counts['Section structure issues'] += 1
                else:
                    issue_counts['Other issues'] += 1

        for issue_type, count in sorted(issue_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"  {issue_type:30s}: {count:4d}")

def main():
    docs_dir = "/home/lewis/src/meal-planner/docs/_indexed/docs"
    validator = MetadataValidator(docs_dir)

    # Get all markdown files
    all_files = list(Path(docs_dir).glob("*.md"))
    total_files = len(all_files)

    print(f"Found {total_files} markdown documents")

    # Progressive disclosure approach
    import random
    random.seed(42)  # Reproducible results

    # Phase 1: Random sample of 10 documents
    sample_10 = random.sample(all_files, min(10, total_files))
    results_10 = validator.validate_sample(sample_10, "Phase 1: Initial Random Sample (10 docs)")

    phase1_pass_rate = (results_10['passed'] / results_10['total'] * 100) if results_10['total'] > 0 else 0

    # Phase 2: If pass rate > 90%, sample 50 more
    if phase1_pass_rate > 90 and total_files > 10:
        remaining_files = [f for f in all_files if f not in sample_10]
        sample_50 = random.sample(remaining_files, min(50, len(remaining_files)))
        results_50 = validator.validate_sample(sample_50, "Phase 2: Extended Random Sample (50 docs)")

        phase2_pass_rate = (results_50['passed'] / results_50['total'] * 100) if results_50['total'] > 0 else 0

        # Phase 3: If still high pass rate, check all
        if phase2_pass_rate > 90 and total_files > 60:
            remaining_files = [f for f in all_files if f not in sample_10 and f not in sample_50]
            validator.validate_sample(remaining_files, f"Phase 3: Remaining Documents ({len(remaining_files)} docs)")
    else:
        # Low pass rate - check all documents
        print("\n⚠️  Phase 1 pass rate below 90% - validating all documents")
        remaining_files = [f for f in all_files if f not in sample_10]
        validator.validate_sample(remaining_files, f"Phase 2: Full Validation ({len(remaining_files)} remaining docs)")

    # Print comprehensive summary
    validator.print_summary()

    # Save detailed results to JSON
    output_file = "/home/lewis/src/meal-planner/validation_results.json"
    with open(output_file, 'w') as f:
        json.dump(validator.results, f, indent=2, default=str)
    print(f"\n📊 Detailed results saved to: {output_file}")

if __name__ == "__main__":
    main()
