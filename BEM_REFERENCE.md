# BEM Naming Convention Reference

## Overview

This project uses **BEM (Block Element Modifier)** methodology for CSS class naming. BEM improves code maintainability, readability, and prevents naming conflicts.

## Core Principles

### 1. Blocks
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

### 2. Elements
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

### 3. Modifiers
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

<!-- Alert with modifier -->
<div class="alert alert--error">Error message</div>
<div class="alert alert--notice">Success message</div>
```

## CSS Structure Rules

### ✅ Correct Approach
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

### ❌ Avoid
```scss
// Don't use tag selectors with BEM
div.block__elem { }

// Don't nest element selectors
.block .block__elem { }

// Don't use modifiers without base class in HTML
<div class="button--primary"></div>  <!-- Missing .button -->
```

## Project BEM Blocks

### Header Block
```html
<header class="header">
  <div class="header__container">
    <div class="header__brand">
      <a class="header__brand-link">...</a>
    </div>
    <nav class="header__nav">
      <span class="header__welcome">...</span>
      <a class="header__link">...</a>
    </nav>
  </div>
</header>
```

### Form Block
```html
<form class="form">
  <div class="form__field">
    <label class="form__label">...</label>
    <input class="form__input">
  </div>
</form>
```

### Button Block
```html
<!-- Default button -->
<button class="button">Click me</button>

<!-- Primary button (modifier) -->
<button class="button button--primary">Submit</button>

<!-- Danger button (modifier) -->
<button class="button button--danger">Delete</button>
```

### Table Block
```html
<table class="table">
  <thead class="table__header">
    <tr class="table__row">
      <th class="table__cell">...</th>
    </tr>
  </thead>
  <tbody>
    <tr class="table__row">
      <td class="table__cell">...</td>
    </tr>
  </tbody>
</table>
```

### Alert Block
```html
<!-- Notice alert -->
<div class="alert alert--notice">Success!</div>

<!-- Error alert -->
<div class="alert alert--error">Error occurred!</div>

<!-- Warning alert -->
<div class="alert alert--warning">Warning!</div>
```

## Benefits of BEM in This Project

1. **No naming conflicts**: Each block is independent
2. **Clear relationships**: Easy to see parent-child relationships
3. **Reusability**: Blocks can be reused anywhere
4. **Maintainability**: Easy to find and modify styles
5. **Readability**: Class names are self-documenting

## Quick Reference

| Pattern | Example | Meaning |
|---------|---------|---------|
| `.block` | `.header` | Independent component |
| `.block__element` | `.header__nav` | Part of header block |
| `.block--modifier` | `.button--primary` | Variant of button block |
| `.block__element--modifier` | `.form__input--error` | Variant of form input |

## Resources

- [Official BEM Documentation](https://getbem.com/naming/)
- Project SCSS: `app/assets/stylesheets/application.scss`
