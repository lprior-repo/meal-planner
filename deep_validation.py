#!/usr/bin/env python3
"""
Deep validation for XML metadata - checks for subtle quality issues.
"""

import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict, Counter
import json

class DeepValidator:
    def __init__(self, docs_dir: str):
        self.docs_dir = Path(docs_dir)
        self.stats = {
            'total_docs': 0,
            'type_distribution': Counter(),
            'category_distribution': Counter(),
            'difficulty_distribution': Counter(),
            'avg_reading_time': 0,
            'avg_sections': 0,
            'avg_features': 0,
            'avg_tags': 0,
            'quality_issues': [],
            'by_system': defaultdict(lambda: {
                'count': 0,
                'avg_reading_time': 0,
                'avg_sections': 0,
                'types': Counter(),
                'difficulties': Counter()
            })
        }

    def extract_metadata(self, content: str):
        """Extract and parse XML metadata."""
        pattern = r'<!--\s*\n(<doc_metadata>.*?</doc_metadata>)\s*\n-->'
        match = re.search(pattern, content, re.DOTALL)
        if not match:
            return None

        xml_str = f'<?xml version="1.0" encoding="UTF-8"?>\n{match.group(1)}'
        try:
            return ET.fromstring(xml_str)
        except:
            return None

    def get_system(self, filename: str) -> str:
        """Get system from filename."""
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

    def analyze_document(self, filepath: Path):
        """Deep analysis of a single document."""
        content = filepath.read_text(encoding='utf-8')
        root = self.extract_metadata(content)

        if not root:
            self.stats['quality_issues'].append({
                'file': str(filepath),
                'issue': 'No metadata found'
            })
            return

        self.stats['total_docs'] += 1
        system = self.get_system(filepath.name)
        self.stats['by_system'][system]['count'] += 1

        # Extract fields
        doc_type = root.find('type')
        category = root.find('category')
        difficulty = root.find('difficulty_level')
        reading_time = root.find('estimated_reading_time')
        sections = root.find('sections')
        features = root.find('features')
        tags = root.find('tags')
        title = root.find('title')
        description = root.find('description')

        # Type distribution
        if doc_type is not None and doc_type.text:
            self.stats['type_distribution'][doc_type.text] += 1
            self.stats['by_system'][system]['types'][doc_type.text] += 1

        # Category distribution
        if category is not None and category.text:
            self.stats['category_distribution'][category.text] += 1

        # Difficulty distribution
        if difficulty is not None and difficulty.text:
            self.stats['difficulty_distribution'][difficulty.text] += 1
            self.stats['by_system'][system]['difficulties'][difficulty.text] += 1

        # Reading time
        if reading_time is not None and reading_time.text:
            try:
                rt = int(reading_time.text)
                self.stats['avg_reading_time'] += rt
                self.stats['by_system'][system]['avg_reading_time'] += rt

                # Quality check: very short or very long
                if rt < 1:
                    self.stats['quality_issues'].append({
                        'file': filepath.name,
                        'issue': f'Reading time too short: {rt} min'
                    })
                elif rt > 30:
                    self.stats['quality_issues'].append({
                        'file': filepath.name,
                        'issue': f'Reading time very long: {rt} min (consider splitting)'
                    })
            except:
                pass

        # Sections
        if sections is not None:
            section_items = sections.findall('section')
            self.stats['avg_sections'] += len(section_items)
            self.stats['by_system'][system]['avg_sections'] += len(section_items)

            # Quality check: no sections
            if len(section_items) == 0:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': 'No sections defined'
                })

            # Check for duplicate section names
            section_names = [s.get('name') for s in section_items if s.get('name')]
            if len(section_names) != len(set(section_names)):
                duplicates = [n for n in section_names if section_names.count(n) > 1]
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Duplicate section names: {set(duplicates)}'
                })

        # Features
        if features is not None:
            feature_items = features.findall('feature')
            self.stats['avg_features'] += len(feature_items)

            # Quality check: no features
            if len(feature_items) == 0:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': 'No features defined'
                })

        # Tags
        if tags is not None and tags.text:
            tag_list = [t.strip() for t in tags.text.split(',') if t.strip()]
            self.stats['avg_tags'] += len(tag_list)

            # Quality check: too few tags
            if len(tag_list) < 2:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Only {len(tag_list)} tag(s) - recommend at least 2'
                })

        # Title quality
        if title is not None and title.text:
            if len(title.text) < 3:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Title too short: "{title.text}"'
                })
            elif len(title.text) > 100:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Title too long ({len(title.text)} chars)'
                })

        # Description quality
        if description is not None and description.text:
            if len(description.text) < 20:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Description too short ({len(description.text)} chars)'
                })
            elif len(description.text) > 500:
                self.stats['quality_issues'].append({
                    'file': filepath.name,
                    'issue': f'Description too long ({len(description.text)} chars)'
                })

    def run(self):
        """Run deep validation on all documents."""
        all_files = sorted(Path(self.docs_dir).glob("*.md"))

        print(f"Deep validation of {len(all_files)} documents...\n")

        for filepath in all_files:
            self.analyze_document(filepath)

        # Calculate averages
        if self.stats['total_docs'] > 0:
            self.stats['avg_reading_time'] /= self.stats['total_docs']
            self.stats['avg_sections'] /= self.stats['total_docs']
            self.stats['avg_features'] /= self.stats['total_docs']
            self.stats['avg_tags'] /= self.stats['total_docs']

            for system_data in self.stats['by_system'].values():
                if system_data['count'] > 0:
                    system_data['avg_reading_time'] /= system_data['count']
                    system_data['avg_sections'] /= system_data['count']

        self.print_report()

    def print_report(self):
        """Print comprehensive quality report."""
        print("="*80)
        print("DEEP VALIDATION REPORT")
        print("="*80)

        print(f"\nTotal Documents Analyzed: {self.stats['total_docs']}")

        print("\n--- CONTENT TYPE DISTRIBUTION ---")
        for doc_type, count in sorted(self.stats['type_distribution'].items()):
            pct = (count / self.stats['total_docs'] * 100) if self.stats['total_docs'] > 0 else 0
            print(f"  {doc_type:12s}: {count:3d} ({pct:5.1f}%)")

        print("\n--- CATEGORY DISTRIBUTION ---")
        for category, count in sorted(self.stats['category_distribution'].items()):
            pct = (count / self.stats['total_docs'] * 100) if self.stats['total_docs'] > 0 else 0
            print(f"  {category:12s}: {count:3d} ({pct:5.1f}%)")

        print("\n--- DIFFICULTY DISTRIBUTION ---")
        for difficulty, count in sorted(self.stats['difficulty_distribution'].items()):
            pct = (count / self.stats['total_docs'] * 100) if self.stats['total_docs'] > 0 else 0
            print(f"  {difficulty:12s}: {count:3d} ({pct:5.1f}%)")

        print("\n--- CONTENT METRICS (AVERAGES) ---")
        print(f"  Reading Time:  {self.stats['avg_reading_time']:.1f} minutes")
        print(f"  Sections:      {self.stats['avg_sections']:.1f} per doc")
        print(f"  Features:      {self.stats['avg_features']:.1f} per doc")
        print(f"  Tags:          {self.stats['avg_tags']:.1f} per doc")

        print("\n--- STATISTICS BY SYSTEM ---")
        for system in sorted(self.stats['by_system'].keys()):
            data = self.stats['by_system'][system]
            print(f"\n  {system.upper()}:")
            print(f"    Documents:     {data['count']}")
            print(f"    Avg Reading:   {data['avg_reading_time']:.1f} min")
            print(f"    Avg Sections:  {data['avg_sections']:.1f}")

            if data['types']:
                print(f"    Types:")
                for dtype, dcount in sorted(data['types'].items()):
                    print(f"      - {dtype}: {dcount}")

            if data['difficulties']:
                print(f"    Difficulties:")
                for diff, dcount in sorted(data['difficulties'].items()):
                    print(f"      - {diff}: {dcount}")

        if self.stats['quality_issues']:
            print("\n" + "="*80)
            print(f"QUALITY RECOMMENDATIONS: {len(self.stats['quality_issues'])} items")
            print("="*80)

            # Group by issue type
            issue_groups = defaultdict(list)
            for item in self.stats['quality_issues']:
                issue_type = item['issue'].split(':')[0]
                issue_groups[issue_type].append(item)

            for issue_type in sorted(issue_groups.keys()):
                items = issue_groups[issue_type]
                print(f"\n{issue_type} ({len(items)} files):")
                for item in items[:10]:  # Show first 10
                    print(f"  - {item['file']}: {item['issue']}")
                if len(items) > 10:
                    print(f"  ... and {len(items) - 10} more")
        else:
            print("\n✓ No quality issues found!")

        # Save detailed stats
        output_file = "/home/lewis/src/meal-planner/deep_validation_stats.json"
        with open(output_file, 'w') as f:
            # Convert Counter to dict for JSON serialization
            serializable_stats = {
                'total_docs': self.stats['total_docs'],
                'type_distribution': dict(self.stats['type_distribution']),
                'category_distribution': dict(self.stats['category_distribution']),
                'difficulty_distribution': dict(self.stats['difficulty_distribution']),
                'avg_reading_time': self.stats['avg_reading_time'],
                'avg_sections': self.stats['avg_sections'],
                'avg_features': self.stats['avg_features'],
                'avg_tags': self.stats['avg_tags'],
                'quality_issues': self.stats['quality_issues'],
                'by_system': {
                    k: {
                        'count': v['count'],
                        'avg_reading_time': v['avg_reading_time'],
                        'avg_sections': v['avg_sections'],
                        'types': dict(v['types']),
                        'difficulties': dict(v['difficulties'])
                    } for k, v in self.stats['by_system'].items()
                }
            }
            json.dump(serializable_stats, f, indent=2)
        print(f"\n📊 Detailed statistics saved to: {output_file}")

if __name__ == "__main__":
    validator = DeepValidator("/home/lewis/src/meal-planner/docs/_indexed/docs")
    validator.run()
