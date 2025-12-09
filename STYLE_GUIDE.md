# Style Guide - Resources Application

This guide covers CSS/SCSS development, BEM naming conventions, and styling standards for the Resources application.

---

## Table of Contents

1. [CSS Development Workflow](#css-development-workflow)
2. [BEM Naming Conventions](#bem-naming-conventions)
3. [Mid-2000s Design System](#mid-2000s-design-system)
4. [Component Reference](#component-reference)

---

## CSS Development Workflow

### Auto-compilation with bin/dev

When running the development server with `bin/dev`, the CSS is automatically watched and recompiled by dartsass.

**Important**: You do NOT need to manually run `bin/rails dartsass:build` when the dev server is running.

#### How it Works

The `Procfile.dev` contains:
```
web: bin/rails server -p 3000
css: bin/rails dartsass:watch
```

The `dartsass:watch` process monitors `app/assets/stylesheets/application.scss` for changes and automatically recompiles to `app/assets/builds/application.css`.

#### Development Workflow

1. Start the dev server: `bin/dev`
2. Edit SCSS files in `app/assets/stylesheets/`
3. Save your changes
4. Refresh the browser (or just curl the page again to see updated HTML with new CSS digest)
5. Changes appear automatically - no manual rebuild needed!

#### Manual Compilation

Only needed when NOT running `bin/dev`:
```bash
bin/rails dartsass:build
```

#### CSS Architecture

- **Source**: `app/assets/stylesheets/application.scss`
- **Compiled**: `app/assets/builds/application.css`
- **Methodology**: BEM (Block Element Modifier)
- **Style**: Mid-2000s aesthetic with tactile buttons and classic forms

#### Checking Changes

When the dev server is running, you can verify CSS changes with:
```bash
curl http://localhost:3000 | grep stylesheet
```

The digest in the filename will change when CSS is recompiled (e.g., `application-abc123.css` → `application-def456.css`).

---

## BEM Naming Conventions

BEM (Block Element Modifier) is a CSS naming methodology that improves development speed, maintainability, and code organization.

### Core Principles

#### 1. Blocks
Standalone, meaningful components that function independently.

**Syntax**: `.block`

**Naming Rules**:
- Lowercase letters, digits, and dashes only
- Use dashes for multi-word names
- No tag names or IDs in CSS selectors

**Examples**:
```html
<header class="header">...</header>
<form class="form">...</form>
<table class="table">...</table>
<button class="button">...</button>
```

#### 2. Elements
Parts of a block that have no standalone meaning; semantically tied to their parent block.

**Syntax**: `.block__element` (double underscore separator)

**Naming Rules**:
- Lowercase letters, digits, dashes, and underscores
- Always prefixed with parent block name
- Never nest element selectors (`.block__elem1__elem2` is wrong)

**Examples**:
```html
<header class="header">
  <div class="header__container">
    <div class="header__brand">
      <a href="#" class="header__brand-link">Logo</a>
    </div>
    <nav class="header__nav">
      <a href="#" class="header__link">Link</a>
    </nav>
  </div>
</header>
```

#### 3. Modifiers
Flags that change the appearance, behavior, or state of blocks or elements.

**Syntax**: `.block--modifier` or `.block__element--modifier` (double dash separator)

**Naming Rules**:
- Lowercase letters, digits, dashes, and underscores
- Always use alongside the base class (not standalone)
- Can have key-value format: `.block--color-red`

**Examples**:
```html
<!-- Button with modifier -->
<button class="button button--primary">Submit</button>
<button class="button button--danger">Delete</button>

<!-- Form with modifier -->
<form class="form form--narrow">...</form>

<!-- Alert with modifier -->
<div class="alert alert--error">Error message</div>
<div class="alert alert--notice">Success message</div>
```

### CSS Structure Rules

#### ✅ Correct Approach
```scss
// Use class selectors only
.form__input {
  border: 1px solid #999;
}

// Modifiers alongside base class
.button--primary {
  background: blue;
}
```

#### ❌ Avoid
```scss
// Don't use tag selectors with BEM
div.block__elem { }

// Don't nest element selectors
.block .block__elem { }

// Don't use modifiers without base class in HTML
<div class="button--primary"></div>  <!-- Missing .button -->
```

---

## Mid-2000s Design System

### Color Palette

```scss
$color-bg-page: #eee;          // Light gray page background
$color-bg-header: #ddd;        // Medium gray header
$color-bg-content: #fff;       // White content areas
$color-border: #999;           // Dark gray borders
$color-border-light: #ccc;     // Light gray borders
$color-text: #333;             // Dark gray text
$color-link: #0066cc;          // Classic blue links
$color-link-visited: #551a8b;  // Purple visited links
$color-link-hover: #003399;    // Darker blue on hover
```

### Typography

- **Font Stack**: Verdana, Geneva, Arial, Helvetica, sans-serif
- **Base Size**: 12px
- **Line Height**: 1.4

### Design Elements

#### Tactile Buttons
- Linear gradients for 3D effect
- Inset shadows for depth
- Active states with inverted gradients
- Border radius: 3px

#### Form Inputs
- Inset box shadows
- 1px solid borders
- Blue focus glow effect
- 2px border radius

#### Tables
- Collapsed borders (1px)
- Alternating row colors
- Yellow highlight on hover
- Gradient header background

---

## Component Reference

### Header Block
```html
<header class="header">
  <div class="header__container">
    <div class="header__brand">
      <a class="header__brand-link">Resources</a>
    </div>
    <nav class="header__nav">
      <span class="header__welcome">Welcome!</span>
      <a class="header__link">Log Out</a>
    </nav>
  </div>
</header>
```

**Features**:
- Sticky positioning (stays at top)
- #DDD background
- Max-width container (1200px)
- Flexbox layout

### Form Block
```html
<form class="form">
  <div class="form__field">
    <label class="form__label">Email</label>
    <input class="form__input">
  </div>
</form>

<!-- Narrow form variant -->
<form class="form form--narrow">
  <!-- Max-width: 20rem -->
</form>
```

**Form Elements**:
- `.form__field` - Field container
- `.form__label` - Bold labels
- `.form__input` - Text inputs
- `.form__textarea` - Textareas
- `.form__select` - Select dropdowns
- `.form__checkbox` - Checkboxes
- `.form__radio` - Radio buttons

**Form Modifiers**:
- `.form--narrow` - Max-width 20rem (for login forms, etc.)

### Button Block
```html
<!-- Default button -->
<button class="button">Click me</button>

<!-- Primary button (modifier) -->
<button class="button button--primary">Submit</button>

<!-- Danger button (modifier) -->
<button class="button button--danger">Delete</button>
```

**Button Modifiers**:
- `.button--primary` - Blue gradient, for primary actions
- `.button--danger` - Red gradient, for delete/destructive actions

### Table Block
```html
<table class="table">
  <thead class="table__header">
    <tr class="table__row">
      <th class="table__cell">Name</th>
    </tr>
  </thead>
  <tbody>
    <tr class="table__row">
      <td class="table__cell">John</td>
    </tr>
  </tbody>
</table>
```

**Features**:
- Collapsed borders (1px solid)
- Gradient header
- Striped rows (even)
- Yellow hover effect

### Alert Block
```html
<!-- Success message -->
<div class="alert alert--notice">Success!</div>

<!-- Error message -->
<div class="alert alert--error">Error occurred!</div>

<!-- Warning message -->
<div class="alert alert--warning">Warning!</div>
```

**Alert Modifiers**:
- `.alert--notice` - Green (success messages)
- `.alert--error` - Red (error messages)
- `.alert--warning` - Yellow (warning messages)

---

## Quick Reference

| Pattern | Example | Meaning |
|---------|---------|---------|
| `.block` | `.header` | Independent component |
| `.block__element` | `.header__nav` | Part of header block |
| `.block--modifier` | `.button--primary` | Variant of button block |
| `.block__element--modifier` | `.form__input--error` | Variant of form input |

---

## Benefits of This Approach

1. **No naming conflicts**: Each block is independent
2. **Clear relationships**: Easy to see parent-child relationships
3. **Reusability**: Blocks can be reused anywhere
4. **Maintainability**: Easy to find and modify styles
5. **Readability**: Class names are self-documenting
6. **Consistent aesthetic**: Mid-2000s design applied throughout

---

## Resources

- Project SCSS: `app/assets/stylesheets/application.scss`
- [Official BEM Documentation](https://getbem.com/naming/)
