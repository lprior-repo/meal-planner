# CSS Design Tokens & Styling Reference

This document serves as the technical reference for the CSS design system implementation.

---

## Design Tokens Reference

All values defined as CSS custom properties for consistency and maintainability.

### Color Tokens

```css
:root {
  /* Primary Color Family */
  --color-primary-50: #f0f7ff;
  --color-primary-100: #e0eofe;
  --color-primary-200: #bae6fd;
  --color-primary-300: #7dd3fc;
  --color-primary-400: #38bdf8;
  --color-primary: #007bff;              /* Primary brand color */
  --color-primary-600: #0284c7;
  --color-primary-700: #0369a1;
  --color-primary-800: #075985;
  --color-primary-900: #0c3d66;
  --color-primary-dark: #0056b3;         /* Dark variant */
  --color-primary-light: #cfe2ff;        /* Light variant */

  /* Status Colors */
  --color-success: #28a745;
  --color-success-light: #d4edda;
  --color-success-dark: #1e7e34;

  --color-warning: #ffc107;
  --color-warning-light: #fff3cd;
  --color-warning-dark: #e0a800;

  --color-danger: #dc3545;
  --color-danger-light: #f8d7da;
  --color-danger-dark: #bd2130;

  --color-info: #17a2b8;
  --color-info-light: #d1ecf1;
  --color-info-dark: #0c5460;

  /* Semantic Macro Colors */
  --color-protein: #28a745;              /* Green */
  --color-fat: #ffc107;                  /* Amber */
  --color-carbs: #17a2b8;                /* Cyan */

  /* Neutral/Gray Scale */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-200: #e5e7eb;
  --color-gray-300: #d1d5db;
  --color-gray-400: #9ca3af;
  --color-gray-500: #6b7280;
  --color-gray-600: #4b5563;
  --color-gray-700: #374151;
  --color-gray-800: #1f2937;
  --color-gray-900: #111827;

  /* Text Colors */
  --color-text: #333333;                 /* Primary text */
  --color-text-secondary: #666666;       /* Secondary text */
  --color-text-muted: #999999;           /* Muted text */
  --color-text-light: #ffffff;           /* Light/inverse text */

  /* Background Colors */
  --color-bg: #ffffff;                   /* Primary background */
  --color-bg-secondary: #f5f5f5;         /* Secondary background */
  --color-bg-tertiary: #eeeeee;          /* Tertiary background */
  --color-bg-overlay: rgba(0, 0, 0, 0.5);

  /* Border Colors */
  --color-border: #e9ecef;               /* Standard border */
  --color-border-light: #f0f0f0;         /* Light border */
  --color-border-dark: #cccccc;          /* Dark border */

  /* Disabled State */
  --color-disabled-bg: #f5f5f5;
  --color-disabled-text: #999999;
  --color-disabled-border: #e0e0e0;

  /* Focus/Interaction */
  --color-focus: var(--color-primary);   /* Focus ring color */
  --color-hover: var(--color-primary-light);
  --color-active: var(--color-primary-dark);
}
```

### Typography Tokens

```css
:root {
  /* Font Family Stack */
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  --font-serif: 'Georgia', 'Times New Roman', serif;
  --font-mono: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;

  /* Font Size Scale (Modular Scale: 1.125) */
  --text-xs: 0.75rem;      /* 12px */
  --text-sm: 0.875rem;     /* 14px */
  --text-base: 1rem;       /* 16px */
  --text-lg: 1.125rem;     /* 18px */
  --text-xl: 1.25rem;      /* 20px */
  --text-2xl: 1.5rem;      /* 24px */
  --text-3xl: 1.875rem;    /* 30px */
  --text-4xl: 2.25rem;     /* 36px */
  --text-5xl: 2.5rem;      /* 40px */

  /* Font Weights */
  --font-thin: 100;
  --font-extralight: 200;
  --font-light: 300;
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  --font-extrabold: 800;
  --font-black: 900;

  /* Line Heights */
  --line-tight: 1.2;
  --line-normal: 1.5;
  --line-relaxed: 1.75;
  --line-loose: 2;

  /* Letter Spacing */
  --letter-tighter: -0.05em;
  --letter-tight: -0.025em;
  --letter-normal: 0em;
  --letter-wide: 0.025em;
  --letter-wider: 0.05em;
  --letter-widest: 0.1em;
}
```

### Spacing Scale (8px Base Unit)

```css
:root {
  --space-0: 0;
  --space-px: 1px;
  --space-0-5: 0.125rem;   /* 2px */
  --space-1: 0.25rem;      /* 4px */
  --space-1-5: 0.375rem;   /* 6px */
  --space-2: 0.5rem;       /* 8px */
  --space-2-5: 0.625rem;   /* 10px */
  --space-3: 0.75rem;      /* 12px */
  --space-3-5: 0.875rem;   /* 14px */
  --space-4: 1rem;         /* 16px */
  --space-5: 1.25rem;      /* 20px */
  --space-6: 1.5rem;       /* 24px */
  --space-7: 1.75rem;      /* 28px */
  --space-8: 2rem;         /* 32px */
  --space-9: 2.25rem;      /* 36px */
  --space-10: 2.5rem;      /* 40px */
  --space-12: 3rem;        /* 48px */
  --space-14: 3.5rem;      /* 56px */
  --space-16: 4rem;        /* 64px */
  --space-20: 5rem;        /* 80px */
  --space-24: 6rem;        /* 96px */
  --space-28: 7rem;        /* 112px */
  --space-32: 8rem;        /* 128px */
}
```

### Border Radius Tokens

```css
:root {
  /* Border Radius */
  --radius-none: 0;
  --radius-px: 1px;
  --radius-sm: 0.25rem;    /* 4px */
  --radius-md: 0.5rem;     /* 8px */
  --radius-lg: 0.75rem;    /* 12px */
  --radius-xl: 1rem;       /* 16px */
  --radius-2xl: 1.5rem;    /* 24px */
  --radius-3xl: 2rem;      /* 32px */
  --radius-full: 9999px;   /* Pill shape */
}
```

### Shadow Tokens

```css
:root {
  /* Shadows (Box-shadow) */
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  --shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  --shadow-inner: inset 0 2px 4px 0 rgba(0, 0, 0, 0.06);
  --shadow-none: 0 0 #0000;

  /* Inset shadows (for borders/outlines) */
  --shadow-inset-sm: inset 0 1px 1px rgba(0, 0, 0, 0.05);
  --shadow-inset-md: inset 0 2px 4px rgba(0, 0, 0, 0.1);
}
```

### Transition/Animation Tokens

```css
:root {
  /* Duration (Milliseconds) */
  --duration-75: 75ms;
  --duration-100: 100ms;
  --duration-150: 150ms;
  --duration-200: 200ms;
  --duration-300: 300ms;
  --duration-500: 500ms;
  --duration-700: 700ms;
  --duration-1000: 1000ms;

  /* Easing Functions */
  --ease-linear: linear;
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);

  /* Transition Shorthand */
  --transition-fast: all var(--duration-150) var(--ease-out);
  --transition: all var(--duration-300) var(--ease-out);
  --transition-slow: all var(--duration-500) var(--ease-out);
}
```

### Breakpoints

```css
/* Mobile-First Approach */
/* base: < 640px (default) */

@media (min-width: 640px) {
  /* sm: >= 640px (small/tablet) */
}

@media (min-width: 768px) {
  /* md: >= 768px (medium/larger tablet) */
}

@media (min-width: 1024px) {
  /* lg: >= 1024px (desktop) */
}

@media (min-width: 1280px) {
  /* xl: >= 1280px (large desktop) */
}

@media (min-width: 1536px) {
  /* 2xl: >= 1536px (extra large) */
}
```

### Container Sizes

```css
:root {
  /* Container max-widths */
  --max-width-xs: 20rem;       /* 320px */
  --max-width-sm: 24rem;       /* 384px */
  --max-width-md: 28rem;       /* 448px */
  --max-width-lg: 32rem;       /* 512px */
  --max-width-xl: 36rem;       /* 576px */
  --max-width-2xl: 42rem;      /* 672px */
  --max-width-3xl: 48rem;      /* 768px */
  --max-width-4xl: 56rem;      /* 896px */
  --max-width-5xl: 64rem;      /* 1024px */
  --max-width-6xl: 72rem;      /* 1152px */
  --max-width-7xl: 80rem;      /* 1280px */
  --max-width-prose: 65ch;     /* For readable text */

  /* Standard container */
  --container-width: 1200px;
  --container-padding: var(--space-4);
}
```

---

## CSS Architecture Structure

### 1. Reset & Defaults

```css
/* priv/static/theme.css (or as first import) */

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
  font-size: 16px;
}

body {
  font-family: var(--font-sans);
  font-size: var(--text-base);
  line-height: var(--line-normal);
  color: var(--color-text);
  background-color: var(--color-bg);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

### 2. Base Elements

```css
/* Headings */
h1 { font-size: var(--text-5xl); font-weight: var(--font-bold); }
h2 { font-size: var(--text-4xl); font-weight: var(--font-bold); }
h3 { font-size: var(--text-3xl); font-weight: var(--font-semibold); }
h4 { font-size: var(--text-2xl); font-weight: var(--font-semibold); }
h5 { font-size: var(--text-xl); font-weight: var(--font-semibold); }
h6 { font-size: var(--text-lg); font-weight: var(--font-semibold); }

/* Links */
a {
  color: var(--color-primary);
  text-decoration: none;
  transition: var(--transition-fast);
}

a:hover {
  color: var(--color-primary-dark);
  text-decoration: underline;
}

a:focus {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

/* Forms */
input,
textarea,
select {
  font-family: var(--font-sans);
  font-size: var(--text-base);
}

button {
  cursor: pointer;
  font-family: var(--font-sans);
}

/* Tables */
table {
  border-collapse: collapse;
  width: 100%;
}

th,
td {
  padding: var(--space-3);
  text-align: left;
  border-bottom: 1px solid var(--color-border);
}

th {
  background-color: var(--color-bg-secondary);
  font-weight: var(--font-semibold);
}
```

### 3. Utility Classes

```css
/* Display & Visibility */
.hidden { display: none; }
.inline { display: inline; }
.inline-block { display: inline-block; }
.block { display: block; }
.flex { display: flex; }
.grid { display: grid; }

/* Flexbox */
.flex-col { flex-direction: column; }
.flex-row { flex-direction: row; }
.flex-wrap { flex-wrap: wrap; }
.justify-start { justify-content: flex-start; }
.justify-center { justify-content: center; }
.justify-end { justify-content: flex-end; }
.justify-between { justify-content: space-between; }
.justify-around { justify-content: space-around; }
.items-start { align-items: flex-start; }
.items-center { align-items: center; }
.items-end { align-items: flex-end; }
.items-stretch { align-items: stretch; }
.gap-0 { gap: var(--space-0); }
.gap-1 { gap: var(--space-1); }
.gap-2 { gap: var(--space-2); }
.gap-3 { gap: var(--space-3); }
.gap-4 { gap: var(--space-4); }
/* ... up to gap-16 */

/* Spacing - Margin */
.m-0 { margin: var(--space-0); }
.m-1 { margin: var(--space-1); }
.m-2 { margin: var(--space-2); }
/* ... */
.mx-auto { margin-left: auto; margin-right: auto; }
.mt-4 { margin-top: var(--space-4); }
.mb-4 { margin-bottom: var(--space-4); }
/* ... */

/* Spacing - Padding */
.p-0 { padding: var(--space-0); }
.p-1 { padding: var(--space-1); }
.p-2 { padding: var(--space-2); }
/* ... */
.px-4 { padding-left: var(--space-4); padding-right: var(--space-4); }
.py-4 { padding-top: var(--space-4); padding-bottom: var(--space-4); }

/* Width & Height */
.w-full { width: 100%; }
.w-screen { width: 100vw; }
.h-full { height: 100%; }
.h-screen { height: 100vh; }
.max-w-prose { max-width: var(--max-width-prose); }
.max-w-container { max-width: var(--container-width); }

/* Text Utilities */
.text-xs { font-size: var(--text-xs); }
.text-sm { font-size: var(--text-sm); }
.text-base { font-size: var(--text-base); }
.text-lg { font-size: var(--text-lg); }
/* ... */
.font-normal { font-weight: var(--font-normal); }
.font-medium { font-weight: var(--font-medium); }
.font-semibold { font-weight: var(--font-semibold); }
.font-bold { font-weight: var(--font-bold); }
.text-center { text-align: center; }
.text-left { text-align: left; }
.text-right { text-align: right; }

/* Color Utilities */
.text-primary { color: var(--color-primary); }
.text-secondary { color: var(--color-text-secondary); }
.text-muted { color: var(--color-text-muted); }
.bg-primary { background-color: var(--color-primary); }
.bg-secondary { background-color: var(--color-bg-secondary); }
.border-primary { border-color: var(--color-primary); }
.border-light { border-color: var(--color-border-light); }

/* Border Utilities */
.border { border: 1px solid var(--color-border); }
.border-0 { border: none; }
.border-t { border-top: 1px solid var(--color-border); }
.border-b { border-bottom: 1px solid var(--color-border); }
.border-l { border-left: 1px solid var(--color-border); }
.border-r { border-right: 1px solid var(--color-border); }
.rounded-none { border-radius: var(--radius-none); }
.rounded-sm { border-radius: var(--radius-sm); }
.rounded-md { border-radius: var(--radius-md); }
.rounded-lg { border-radius: var(--radius-lg); }
.rounded-xl { border-radius: var(--radius-xl); }
.rounded-full { border-radius: var(--radius-full); }

/* Opacity */
.opacity-0 { opacity: 0; }
.opacity-50 { opacity: 0.5; }
.opacity-100 { opacity: 1; }

/* Transitions */
.transition { transition: var(--transition); }
.transition-fast { transition: var(--transition-fast); }
.transition-slow { transition: var(--transition-slow); }
```

### 4. Component Styles

```css
/* Button Components */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-2) var(--space-4);
  border: 1px solid transparent;
  border-radius: var(--radius-md);
  font-size: var(--text-base);
  font-weight: var(--font-medium);
  cursor: pointer;
  transition: var(--transition-fast);
  text-decoration: none;
  white-space: nowrap;
}

.btn:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.btn:active {
  transform: translateY(0);
  box-shadow: var(--shadow-sm);
}

.btn:focus {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

.btn:disabled,
.btn.is-disabled {
  background-color: var(--color-disabled-bg);
  color: var(--color-disabled-text);
  border-color: var(--color-disabled-border);
  cursor: not-allowed;
  opacity: 0.6;
}

.btn-primary {
  background-color: var(--color-primary);
  color: white;
}

.btn-primary:hover {
  background-color: var(--color-primary-dark);
}

.btn-secondary {
  background-color: var(--color-bg-secondary);
  color: var(--color-text);
  border-color: var(--color-border);
}

.btn-secondary:hover {
  background-color: var(--color-border);
}

.btn-danger {
  background-color: var(--color-danger);
  color: white;
}

.btn-danger:hover {
  background-color: var(--color-danger-dark);
}

.btn-sm {
  padding: var(--space-1) var(--space-3);
  font-size: var(--text-sm);
}

.btn-lg {
  padding: var(--space-3) var(--space-6);
  font-size: var(--text-lg);
}

/* Card Components */
.card {
  background-color: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-4);
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
}

.card:hover {
  box-shadow: var(--shadow-md);
}

.card-header {
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-4);
  border-bottom: 1px solid var(--color-border);
}

.card-body {
  padding: var(--space-4);
}

.card-footer {
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: 1px solid var(--color-border);
  display: flex;
  gap: var(--space-2);
}

/* Input Components */
.input,
.input-text,
.input-search {
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  font-size: var(--text-base);
  transition: var(--transition-fast);
}

.input:focus,
.input-text:focus,
.input-search:focus {
  outline: none;
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.input:disabled {
  background-color: var(--color-disabled-bg);
  color: var(--color-disabled-text);
  cursor: not-allowed;
}

/* Progress Bar */
.progress-bar {
  width: 100%;
  height: var(--space-2);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-full);
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background-color: var(--color-primary);
  border-radius: var(--radius-full);
  transition: width var(--duration-500) var(--ease-out);
}

/* Macro Bar */
.macro-bar {
  margin-bottom: var(--space-4);
}

.macro-bar-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
}

/* Badges */
.badge {
  display: inline-block;
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-full);
  font-size: var(--text-xs);
  font-weight: var(--font-semibold);
  white-space: nowrap;
}

.badge-primary {
  background-color: var(--color-primary-light);
  color: var(--color-primary-dark);
}

.badge-success {
  background-color: var(--color-success-light);
  color: var(--color-success-dark);
}

.macro-badge {
  display: inline-block;
  padding: var(--space-1) var(--space-2);
  margin-right: var(--space-2);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
}
```

### 5. Layout Components

```css
/* Container */
.container {
  width: 100%;
  max-width: var(--container-width);
  margin-left: auto;
  margin-right: auto;
  padding-left: var(--container-padding);
  padding-right: var(--container-padding);
}

/* Grid */
.grid {
  display: grid;
  gap: var(--space-4);
}

.grid-cols-1 { grid-template-columns: repeat(1, minmax(0, 1fr)); }
.grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.grid-cols-4 { grid-template-columns: repeat(4, minmax(0, 1fr)); }

/* Responsive Grid */
@media (max-width: 768px) {
  .grid-cols-2, .grid-cols-3, .grid-cols-4 {
    grid-template-columns: repeat(1, minmax(0, 1fr));
  }
}

@media (min-width: 768px) {
  .grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .grid-cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}

/* Section */
.section {
  padding: var(--space-6) var(--space-4);
}

.section-lg {
  padding: var(--space-12) var(--space-4);
}
```

### 6. Component-Specific Styles

```css
/* Recipe Card */
.recipe-card {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
  background-color: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  text-decoration: none;
  color: inherit;
  transition: var(--transition);
}

.recipe-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.recipe-title {
  font-size: var(--text-lg);
  font-weight: var(--font-bold);
}

.recipe-category {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
}

.recipe-macros {
  display: flex;
  gap: var(--space-2);
}

.recipe-calories {
  font-weight: var(--font-semibold);
  color: var(--color-primary);
}

/* Food Search */
.search-box {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
}

.search-input {
  flex: 1;
  min-width: 0;
}

.food-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.food-item {
  padding: var(--space-3);
  background-color: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  text-decoration: none;
  color: inherit;
  transition: var(--transition-fast);
}

.food-item:hover {
  background-color: var(--color-bg-secondary);
  border-color: var(--color-primary);
}

.food-info {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.food-name {
  font-weight: var(--font-medium);
}

.food-type {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
}

/* Dashboard */
.dashboard {
  padding: var(--space-4);
}

.calorie-summary {
  text-align: center;
  margin-bottom: var(--space-6);
  padding: var(--space-6);
  background: linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-dark) 100%);
  border-radius: var(--radius-lg);
  color: white;
}

.big-number {
  font-size: var(--text-5xl);
  font-weight: var(--font-bold);
}

.unit {
  font-size: var(--text-lg);
  opacity: 0.9;
}

.macro-bars {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.daily-log-section {
  margin-top: var(--space-6);
}

.meal-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.meal-item {
  padding: var(--space-3);
  background-color: var(--color-bg-secondary);
  border-left: 4px solid var(--color-primary);
  border-radius: var(--radius-md);
}
```

### 7. Responsive Overrides

```css
@media (max-width: 640px) {
  .container {
    padding-left: var(--space-2);
    padding-right: var(--space-2);
  }

  h1 { font-size: var(--text-4xl); }
  h2 { font-size: var(--text-3xl); }
  h3 { font-size: var(--text-2xl); }

  .hidden-sm { display: none; }
  .block-sm { display: block; }

  .grid-cols-2,
  .grid-cols-3,
  .grid-cols-4 {
    grid-template-columns: repeat(1, minmax(0, 1fr));
  }

  .search-box {
    flex-direction: column;
  }

  .search-input {
    width: 100%;
  }
}

@media (min-width: 768px) {
  .hidden-md { display: none; }
  .block-md { display: block; }

  .grid-cols-2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .grid-cols-3 {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (min-width: 1024px) {
  .hidden-lg { display: none; }
  .block-lg { display: block; }

  .grid-cols-3 {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
  .grid-cols-4 {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}
```

---

## CSS File Organization

### Import Order (in main styles.css)

```css
/* 1. Design System */
@import url('theme.css');

/* 2. Utility Classes */
@import url('utilities.css');

/* 3. Component Styles */
@import url('components.css');

/* 4. Responsive Overrides */
@import url('responsive.css');
```

---

## Color Usage Guidelines

### Semantic Color Usage

- **Primary**: Interactive elements (buttons, links, focus states)
- **Success**: Positive feedback, confirmations, completed tasks
- **Warning**: Caution, requires attention, pending actions
- **Danger**: Destructive actions, errors, critical issues
- **Info**: Informational messages, neutral updates
- **Protein/Fat/Carbs**: Nutrition tracking visualization

### Contrast Requirements

- **Normal Text**: 4.5:1 contrast ratio (WCAG AA)
- **Large Text**: 3:1 contrast ratio (WCAG AA)
- **AAA**: 7:1 for normal, 4.5:1 for large (optional)

---

**Document Version**: 1.0
**Generated**: 2025-12-03
