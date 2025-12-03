/**
 * Recipe Form Dynamic Functionality
 * Handles ingredient/instruction management, validation, and form submission
 */

(function() {
  'use strict';

  // Configuration
  const CONFIG = {
    maxIngredients: 50,
    maxInstructions: 50,
    minIngredients: 1,
    minInstructions: 1,
    debounceDelay: 300
  };

  // State management
  let ingredientCount = 0;
  let instructionCount = 0;
  let isSubmitting = false;

  /**
   * Initialize the recipe form when DOM is ready
   */
  function init() {
    const form = document.getElementById('recipe-form');
    if (!form) return;

    // Initialize counters based on existing rows
    ingredientCount = document.querySelectorAll('.ingredient-row').length;
    instructionCount = document.querySelectorAll('.instruction-row').length;

    // Setup event listeners
    setupIngredientControls();
    setupInstructionControls();
    setupFormValidation(form);
    setupFormSubmission(form);

    // Enable keyboard navigation
    setupKeyboardNavigation();

    // Initial state update
    updateIngredientButtons();
    updateInstructionButtons();
  }

  /**
   * Setup ingredient add/remove controls
   */
  function setupIngredientControls() {
    const addButton = document.getElementById('add-ingredient');
    const container = document.getElementById('ingredients-container');

    if (!addButton || !container) return;

    // Add ingredient button
    addButton.addEventListener('click', function() {
      addIngredientRow();
    });

    // Remove ingredient buttons (event delegation)
    container.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-ingredient') ||
          e.target.closest('.remove-ingredient')) {
        const button = e.target.classList.contains('remove-ingredient')
          ? e.target
          : e.target.closest('.remove-ingredient');
        removeIngredientRow(button);
      }
    });
  }

  /**
   * Setup instruction add/remove controls
   */
  function setupInstructionControls() {
    const addButton = document.getElementById('add-instruction');
    const container = document.getElementById('instructions-container');

    if (!addButton || !container) return;

    // Add instruction button
    addButton.addEventListener('click', function() {
      addInstructionRow();
    });

    // Remove instruction buttons (event delegation)
    container.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-instruction') ||
          e.target.closest('.remove-instruction')) {
        const button = e.target.classList.contains('remove-instruction')
          ? e.target
          : e.target.closest('.remove-instruction');
        removeInstructionRow(button);
      }
    });
  }

  /**
   * Add a new ingredient row
   */
  function addIngredientRow() {
    if (ingredientCount >= CONFIG.maxIngredients) {
      showError(`Maximum ${CONFIG.maxIngredients} ingredients allowed`);
      return;
    }

    const container = document.getElementById('ingredients-container');
    const newRow = createIngredientRow(ingredientCount);

    container.appendChild(newRow);
    ingredientCount++;

    // Focus on the new ingredient name input
    const nameInput = newRow.querySelector('input[name^="ingredient_name"]');
    if (nameInput) nameInput.focus();

    updateIngredientButtons();
    announceToScreenReader('Ingredient row added');
  }

  /**
   * Remove an ingredient row
   */
  function removeIngredientRow(button) {
    if (ingredientCount <= CONFIG.minIngredients) {
      showError(`At least ${CONFIG.minIngredients} ingredient required`);
      return;
    }

    const row = button.closest('.ingredient-row');
    if (!row) return;

    // Animate removal
    row.style.opacity = '0';
    row.style.transform = 'translateX(-20px)';

    setTimeout(function() {
      row.remove();
      ingredientCount--;
      renumberIngredients();
      updateIngredientButtons();
      announceToScreenReader('Ingredient row removed');
    }, 200);
  }

  /**
   * Create a new ingredient row element
   */
  function createIngredientRow(index) {
    const row = document.createElement('div');
    row.className = 'ingredient-row form-row';
    row.setAttribute('role', 'group');
    row.setAttribute('aria-label', `Ingredient ${index + 1}`);

    row.innerHTML = `
      <div class="form-group">
        <label for="ingredient_name_${index}">
          Ingredient Name
          <span class="required" aria-label="required">*</span>
        </label>
        <input
          type="text"
          id="ingredient_name_${index}"
          name="ingredient_name_${index}"
          class="form-input"
          required
          aria-required="true"
          placeholder="e.g., Chicken breast"
        />
      </div>

      <div class="form-group form-group-small">
        <label for="ingredient_amount_${index}">
          Amount
          <span class="required" aria-label="required">*</span>
        </label>
        <input
          type="number"
          id="ingredient_amount_${index}"
          name="ingredient_amount_${index}"
          class="form-input"
          required
          aria-required="true"
          min="0"
          step="0.01"
          placeholder="1"
        />
      </div>

      <div class="form-group form-group-small">
        <label for="ingredient_unit_${index}">
          Unit
          <span class="required" aria-label="required">*</span>
        </label>
        <select
          id="ingredient_unit_${index}"
          name="ingredient_unit_${index}"
          class="form-input"
          required
          aria-required="true"
        >
          <option value="">Select unit</option>
          <option value="g">g (grams)</option>
          <option value="kg">kg (kilograms)</option>
          <option value="ml">ml (milliliters)</option>
          <option value="l">l (liters)</option>
          <option value="cup">cup</option>
          <option value="tbsp">tbsp (tablespoon)</option>
          <option value="tsp">tsp (teaspoon)</option>
          <option value="oz">oz (ounces)</option>
          <option value="lb">lb (pounds)</option>
          <option value="piece">piece</option>
        </select>
      </div>

      <div class="form-group-actions">
        <button
          type="button"
          class="btn btn-danger btn-icon remove-ingredient"
          aria-label="Remove ingredient ${index + 1}"
          title="Remove ingredient"
        >
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    `;

    return row;
  }

  /**
   * Renumber ingredient fields after removal
   */
  function renumberIngredients() {
    const rows = document.querySelectorAll('.ingredient-row');
    rows.forEach(function(row, index) {
      row.setAttribute('aria-label', `Ingredient ${index + 1}`);

      const inputs = row.querySelectorAll('input, select');
      inputs.forEach(function(input) {
        const baseName = input.name.replace(/_\d+$/, '');
        input.name = `${baseName}_${index}`;
        input.id = `${baseName}_${index}`;
      });

      const labels = row.querySelectorAll('label');
      labels.forEach(function(label) {
        const forAttr = label.getAttribute('for');
        if (forAttr) {
          const baseName = forAttr.replace(/_\d+$/, '');
          label.setAttribute('for', `${baseName}_${index}`);
        }
      });

      const removeBtn = row.querySelector('.remove-ingredient');
      if (removeBtn) {
        removeBtn.setAttribute('aria-label', `Remove ingredient ${index + 1}`);
      }
    });
  }

  /**
   * Update ingredient button states
   */
  function updateIngredientButtons() {
    const addButton = document.getElementById('add-ingredient');
    const removeButtons = document.querySelectorAll('.remove-ingredient');

    if (addButton) {
      addButton.disabled = ingredientCount >= CONFIG.maxIngredients;
    }

    removeButtons.forEach(function(button) {
      button.disabled = ingredientCount <= CONFIG.minIngredients;
    });
  }

  /**
   * Add a new instruction row
   */
  function addInstructionRow() {
    if (instructionCount >= CONFIG.maxInstructions) {
      showError(`Maximum ${CONFIG.maxInstructions} instructions allowed`);
      return;
    }

    const container = document.getElementById('instructions-container');
    const newRow = createInstructionRow(instructionCount);

    container.appendChild(newRow);
    instructionCount++;

    // Focus on the new textarea
    const textarea = newRow.querySelector('textarea');
    if (textarea) textarea.focus();

    updateInstructionButtons();
    announceToScreenReader('Instruction step added');
  }

  /**
   * Remove an instruction row
   */
  function removeInstructionRow(button) {
    if (instructionCount <= CONFIG.minInstructions) {
      showError(`At least ${CONFIG.minInstructions} instruction required`);
      return;
    }

    const row = button.closest('.instruction-row');
    if (!row) return;

    // Animate removal
    row.style.opacity = '0';
    row.style.transform = 'translateX(-20px)';

    setTimeout(function() {
      row.remove();
      instructionCount--;
      renumberInstructions();
      updateInstructionButtons();
      announceToScreenReader('Instruction step removed');
    }, 200);
  }

  /**
   * Create a new instruction row element
   */
  function createInstructionRow(index) {
    const row = document.createElement('div');
    row.className = 'instruction-row form-row';
    row.setAttribute('role', 'group');
    row.setAttribute('aria-label', `Step ${index + 1}`);

    row.innerHTML = `
      <div class="instruction-number" aria-hidden="true">${index + 1}</div>
      <div class="form-group form-group-flex">
        <label for="instruction_${index}" class="visually-hidden">
          Instruction step ${index + 1}
        </label>
        <textarea
          id="instruction_${index}"
          name="instruction_${index}"
          class="form-input"
          rows="3"
          required
          aria-required="true"
          placeholder="Describe this step..."
        ></textarea>
      </div>
      <div class="form-group-actions">
        <button
          type="button"
          class="btn btn-danger btn-icon remove-instruction"
          aria-label="Remove step ${index + 1}"
          title="Remove step"
        >
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    `;

    return row;
  }

  /**
   * Renumber instruction fields after removal
   */
  function renumberInstructions() {
    const rows = document.querySelectorAll('.instruction-row');
    rows.forEach(function(row, index) {
      row.setAttribute('aria-label', `Step ${index + 1}`);

      const number = row.querySelector('.instruction-number');
      if (number) number.textContent = index + 1;

      const textarea = row.querySelector('textarea');
      if (textarea) {
        textarea.name = `instruction_${index}`;
        textarea.id = `instruction_${index}`;
      }

      const label = row.querySelector('label');
      if (label) {
        label.setAttribute('for', `instruction_${index}`);
        label.textContent = `Instruction step ${index + 1}`;
      }

      const removeBtn = row.querySelector('.remove-instruction');
      if (removeBtn) {
        removeBtn.setAttribute('aria-label', `Remove step ${index + 1}`);
      }
    });
  }

  /**
   * Update instruction button states
   */
  function updateInstructionButtons() {
    const addButton = document.getElementById('add-instruction');
    const removeButtons = document.querySelectorAll('.remove-instruction');

    if (addButton) {
      addButton.disabled = instructionCount >= CONFIG.maxInstructions;
    }

    removeButtons.forEach(function(button) {
      button.disabled = instructionCount <= CONFIG.minInstructions;
    });
  }

  /**
   * Setup client-side form validation
   */
  function setupFormValidation(form) {
    // Real-time validation on blur
    form.addEventListener('blur', function(e) {
      if (e.target.classList.contains('form-input')) {
        validateField(e.target);
      }
    }, true);

    // Clear validation on input
    form.addEventListener('input', function(e) {
      if (e.target.classList.contains('form-input') && e.target.classList.contains('error')) {
        clearFieldError(e.target);
      }
    });
  }

  /**
   * Validate a single form field
   */
  function validateField(field) {
    const value = field.value.trim();
    let error = null;

    // Required field validation
    if (field.hasAttribute('required') && !value) {
      error = 'This field is required';
    }

    // Number validation
    if (field.type === 'number' && value) {
      const num = parseFloat(value);
      const min = parseFloat(field.min);
      const max = parseFloat(field.max);

      if (isNaN(num)) {
        error = 'Please enter a valid number';
      } else if (!isNaN(min) && num < min) {
        error = `Value must be at least ${min}`;
      } else if (!isNaN(max) && num > max) {
        error = `Value must be at most ${max}`;
      }
    }

    // Text length validation
    if (field.type === 'text' && value) {
      if (value.length > 200) {
        error = 'Text is too long (max 200 characters)';
      }
    }

    if (error) {
      showFieldError(field, error);
      return false;
    } else {
      clearFieldError(field);
      return true;
    }
  }

  /**
   * Show field-specific error
   */
  function showFieldError(field, message) {
    field.classList.add('error');
    field.setAttribute('aria-invalid', 'true');

    let errorMsg = field.parentElement.querySelector('.error-message');
    if (!errorMsg) {
      errorMsg = document.createElement('span');
      errorMsg.className = 'error-message';
      errorMsg.setAttribute('role', 'alert');
      field.parentElement.appendChild(errorMsg);
    }
    errorMsg.textContent = message;
  }

  /**
   * Clear field error
   */
  function clearFieldError(field) {
    field.classList.remove('error');
    field.removeAttribute('aria-invalid');

    const errorMsg = field.parentElement.querySelector('.error-message');
    if (errorMsg) {
      errorMsg.remove();
    }
  }

  /**
   * Validate entire form
   */
  function validateForm(form) {
    let isValid = true;
    const errors = [];

    // Validate all required fields
    const requiredFields = form.querySelectorAll('[required]');
    requiredFields.forEach(function(field) {
      if (!validateField(field)) {
        isValid = false;
        errors.push(`${field.name || field.id}: validation failed`);
      }
    });

    // Validate at least one ingredient
    const ingredientRows = form.querySelectorAll('.ingredient-row');
    if (ingredientRows.length === 0) {
      isValid = false;
      errors.push('At least one ingredient is required');
    }

    // Validate at least one instruction
    const instructionRows = form.querySelectorAll('.instruction-row');
    if (instructionRows.length === 0) {
      isValid = false;
      errors.push('At least one instruction is required');
    }

    return { isValid, errors };
  }

  /**
   * Setup form submission handling
   */
  function setupFormSubmission(form) {
    form.addEventListener('submit', function(e) {
      e.preventDefault();

      if (isSubmitting) return;

      // Clear previous errors
      clearAllErrors();

      // Validate form
      const validation = validateForm(form);
      if (!validation.isValid) {
        showError('Please correct the errors before submitting');
        // Focus on first error
        const firstError = form.querySelector('.error');
        if (firstError) firstError.focus();
        return;
      }

      // Submit form
      submitForm(form);
    });
  }

  /**
   * Submit form with loading state
   */
  function submitForm(form) {
    isSubmitting = true;

    const submitButton = form.querySelector('button[type="submit"]');
    const originalText = submitButton ? submitButton.textContent : '';

    // Show loading state
    if (submitButton) {
      submitButton.disabled = true;
      submitButton.classList.add('loading');
      submitButton.textContent = 'Saving...';
    }

    showInfo('Saving recipe...');

    // Create FormData and submit
    const formData = new FormData(form);

    // Use native form submission
    form.submit();

    // Note: In a real app, you might want to use fetch() for AJAX submission:
    /*
    fetch(form.action, {
      method: form.method,
      body: formData
    })
    .then(response => {
      if (response.ok) {
        showSuccess('Recipe saved successfully!');
        setTimeout(() => {
          window.location.href = response.url;
        }, 1000);
      } else {
        throw new Error('Failed to save recipe');
      }
    })
    .catch(error => {
      showError(error.message || 'Failed to save recipe. Please try again.');
      isSubmitting = false;
      if (submitButton) {
        submitButton.disabled = false;
        submitButton.classList.remove('loading');
        submitButton.textContent = originalText;
      }
    });
    */
  }

  /**
   * Setup keyboard navigation
   */
  function setupKeyboardNavigation() {
    // Allow Enter key to trigger add buttons
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Enter' && e.target.classList.contains('btn-secondary')) {
        e.preventDefault();
        e.target.click();
      }

      // Allow Escape to cancel remove action
      if (e.key === 'Escape' && e.target.classList.contains('btn-danger')) {
        e.target.blur();
      }
    });
  }

  /**
   * Show error message
   */
  function showError(message) {
    showNotification(message, 'error');
  }

  /**
   * Show info message
   */
  function showInfo(message) {
    showNotification(message, 'info');
  }

  /**
   * Show success message
   */
  function showSuccess(message) {
    showNotification(message, 'success');
  }

  /**
   * Show notification
   */
  function showNotification(message, type) {
    // Remove existing notifications
    const existing = document.querySelector('.notification');
    if (existing) existing.remove();

    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.setAttribute('role', 'alert');
    notification.setAttribute('aria-live', 'polite');
    notification.textContent = message;

    document.body.appendChild(notification);

    // Animate in
    setTimeout(function() {
      notification.classList.add('show');
    }, 10);

    // Auto-remove after 5 seconds
    setTimeout(function() {
      notification.classList.remove('show');
      setTimeout(function() {
        notification.remove();
      }, 300);
    }, 5000);
  }

  /**
   * Clear all form errors
   */
  function clearAllErrors() {
    const errorFields = document.querySelectorAll('.form-input.error');
    errorFields.forEach(clearFieldError);

    const errorMessages = document.querySelectorAll('.error-message');
    errorMessages.forEach(function(msg) {
      msg.remove();
    });
  }

  /**
   * Announce to screen readers
   */
  function announceToScreenReader(message) {
    const announcement = document.createElement('div');
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.className = 'visually-hidden';
    announcement.textContent = message;

    document.body.appendChild(announcement);

    setTimeout(function() {
      announcement.remove();
    }, 1000);
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Export for testing (if in a module environment)
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      init,
      addIngredientRow,
      removeIngredientRow,
      addInstructionRow,
      removeInstructionRow,
      validateForm
    };
  }

})();
