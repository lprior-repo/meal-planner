/**
 * Filter Chips - Client-Side Filter Management
 *
 * Provides interactive filter chip management with URL query parameter syncing.
 * Enables fast client-side filtering without full page reloads.
 *
 * Features:
 * - Click handlers for filter chips
 * - URL query parameter synchronization
 * - Toggle active state visually
 * - Trigger search with new filters
 * - Category dropdown management
 * - Keyboard accessibility (Enter, Escape, Space)
 * - Performance optimized with event delegation
 *
 * Usage:
 * <div class="filter-chips-container" data-filters-for="results">
 *   <div class="filter-chip" data-filter-type="category" data-filter-value="vegetables">
 *     <span class="chip-label">Vegetables</span>
 *     <button class="chip-remove" aria-label="Remove vegetables filter">×</button>
 *   </div>
 * </div>
 *
 * API:
 * - FilterChips.init(options) - Initialize filter chips
 * - FilterChips.setFilters(filters) - Set filters programmatically
 * - FilterChips.getFilters() - Get current active filters
 * - FilterChips.clearAll() - Clear all filters
 * - FilterChips.on(event, callback) - Listen to filter events
 */

(function() {
  'use strict';

  // ===================================================================
  // CONFIGURATION
  // ===================================================================

  const CONFIG = {
    debounceDelay: 200, // ms delay before search trigger
    storageKey: 'filter-chips-state', // LocalStorage key
    urlParamPrefix: 'filter_', // Prefix for URL parameters
  };

  // ===================================================================
  // STATE MANAGEMENT
  // ===================================================================

  let state = {
    activeFilters: {}, // { filterType: [value1, value2, ...] }
    categoryDropdownOpen: false,
    selectedCategory: null,
    debounceTimer: null,
    eventListeners: {
      filterChange: [],
      filterApply: [],
      dropdownOpen: [],
      dropdownClose: [],
    },
  };

  // ===================================================================
  // INITIALIZATION
  // ===================================================================

  /**
   * Initialize filter chips system
   * @param {Object} options - Configuration options
   * @param {boolean} options.loadFromUrl - Load filters from URL query params
   * @param {boolean} options.persistToStorage - Save filters to localStorage
   * @param {Function} options.onFilterChange - Callback when filters change
   * @param {Function} options.onSearch - Callback to trigger search
   */
  function init(options = {}) {
    options = {
      loadFromUrl: true,
      persistToStorage: true,
      onFilterChange: null,
      onSearch: null,
      ...options,
    };

    // Load initial state
    if (options.loadFromUrl) {
      loadFiltersFromUrl();
    } else if (options.persistToStorage) {
      loadFiltersFromStorage();
    }

    // Setup event handlers
    setupChipClickHandlers();
    setupCategoryDropdown();
    setupClearAllButton();
    setupKeyboardNavigation();

    // Register callbacks
    if (options.onFilterChange) {
      state.eventListeners.filterChange.push(options.onFilterChange);
    }
    if (options.onSearch) {
      state.eventListeners.filterApply.push(options.onSearch);
    }

    // Apply initial filters to UI
    applyFiltersToUI();
  }

  // ===================================================================
  // URL QUERY PARAMETER HANDLING
  // ===================================================================

  /**
   * Load filters from URL query parameters
   * Supports formats like: ?filter_category=vegetables&filter_category=fruits
   */
  function loadFiltersFromUrl() {
    const params = new URLSearchParams(window.location.search);
    const filters = {};

    // Extract all filter parameters
    for (const [key, value] of params.entries()) {
      if (key.startsWith(CONFIG.urlParamPrefix)) {
        const filterType = key.substring(CONFIG.urlParamPrefix.length);
        if (!filters[filterType]) {
          filters[filterType] = [];
        }
        filters[filterType].push(value);
      }
    }

    state.activeFilters = filters;
  }

  /**
   * Update URL with current filters
   * Creates clean query string without page reload
   */
  function updateUrl() {
    const params = new URLSearchParams();

    // Add filter parameters
    for (const [filterType, values] of Object.entries(state.activeFilters)) {
      if (Array.isArray(values)) {
        values.forEach(value => {
          params.append(CONFIG.urlParamPrefix + filterType, value);
        });
      }
    }

    // Update URL without reload
    const queryString = params.toString();
    const newUrl = queryString
      ? `${window.location.pathname}?${queryString}`
      : window.location.pathname;

    window.history.replaceState({}, '', newUrl);
  }

  // ===================================================================
  // LOCALSTORAGE PERSISTENCE
  // ===================================================================

  /**
   * Load filters from localStorage
   */
  function loadFiltersFromStorage() {
    try {
      const saved = localStorage.getItem(CONFIG.storageKey);
      if (saved) {
        state.activeFilters = JSON.parse(saved);
      }
    } catch (e) {
      console.warn('Failed to load filters from storage:', e);
    }
  }

  /**
   * Save filters to localStorage
   */
  function saveFiltersToStorage() {
    try {
      localStorage.setItem(CONFIG.storageKey, JSON.stringify(state.activeFilters));
    } catch (e) {
      console.warn('Failed to save filters to storage:', e);
    }
  }

  // ===================================================================
  // FILTER CHIP CLICK HANDLERS
  // ===================================================================

  /**
   * Setup event delegation for filter chip clicks
   */
  function setupChipClickHandlers() {
    const container = document.querySelector('.filter-chips-container');
    if (!container) return;

    container.addEventListener('click', handleChipClick);
  }

  /**
   * Handle filter chip click events
   * @param {Event} event - Click event
   */
  function handleChipClick(event) {
    const chip = event.target.closest('.filter-chip');
    if (!chip) return;

    const removeButton = event.target.closest('.chip-remove');
    if (removeButton) {
      handleRemoveChip(chip);
    } else {
      handleToggleChip(chip);
    }
  }

  /**
   * Handle chip click to toggle on/off
   * @param {HTMLElement} chip - Filter chip element
   */
  function handleToggleChip(chip) {
    const filterType = chip.dataset.filterType;
    const filterValue = chip.dataset.filterValue;

    if (!filterType || !filterValue) return;

    // Toggle filter
    const isActive = chip.classList.contains('active');
    if (isActive) {
      removeFilter(filterType, filterValue);
    } else {
      addFilter(filterType, filterValue);
    }

    // Update UI and URL
    applyFiltersToUI();
    updateUrl();
    saveFiltersToStorage();

    // Trigger callbacks
    emitEvent('filterChange', {
      filterType,
      filterValue,
      isActive: !isActive,
    });

    debouncedTriggerSearch();
  }

  /**
   * Handle remove chip click
   * @param {HTMLElement} chip - Filter chip element
   */
  function handleRemoveChip(chip) {
    const filterType = chip.dataset.filterType;
    const filterValue = chip.dataset.filterValue;

    if (!filterType || !filterValue) return;

    removeFilter(filterType, filterValue);
    applyFiltersToUI();
    updateUrl();
    saveFiltersToStorage();

    emitEvent('filterChange', {
      filterType,
      filterValue,
      isActive: false,
      removed: true,
    });

    debouncedTriggerSearch();

    // Focus management: move focus to previous chip or container
    const chip_ = document.querySelector(
      `.filter-chip[data-filter-type="${filterType}"][data-filter-value="${filterValue}"]`
    );
    const previousChip = chip_.previousElementSibling;
    if (previousChip && previousChip.classList.contains('filter-chip')) {
      previousChip.focus();
    } else {
      const container = document.querySelector('.filter-chips-container');
      if (container) container.focus();
    }
  }

  // ===================================================================
  // FILTER STATE MANAGEMENT
  // ===================================================================

  /**
   * Add a filter value
   * @param {string} filterType - Type of filter (e.g., 'category', 'verified')
   * @param {string} filterValue - Filter value to add
   */
  function addFilter(filterType, filterValue) {
    if (!state.activeFilters[filterType]) {
      state.activeFilters[filterType] = [];
    }

    if (!state.activeFilters[filterType].includes(filterValue)) {
      state.activeFilters[filterType].push(filterValue);
    }
  }

  /**
   * Remove a filter value
   * @param {string} filterType - Type of filter
   * @param {string} filterValue - Filter value to remove
   */
  function removeFilter(filterType, filterValue) {
    if (!state.activeFilters[filterType]) return;

    state.activeFilters[filterType] = state.activeFilters[filterType].filter(
      v => v !== filterValue
    );

    // Clean up empty filter types
    if (state.activeFilters[filterType].length === 0) {
      delete state.activeFilters[filterType];
    }
  }

  /**
   * Check if a filter is active
   * @param {string} filterType - Type of filter
   * @param {string} filterValue - Filter value to check
   * @returns {boolean} Whether the filter is active
   */
  function isFilterActive(filterType, filterValue) {
    const filters = state.activeFilters[filterType];
    return filters && filters.includes(filterValue);
  }

  /**
   * Get all active filters
   * @returns {Object} Active filters object
   */
  function getActiveFilters() {
    return JSON.parse(JSON.stringify(state.activeFilters));
  }

  /**
   * Set filters programmatically
   * @param {Object} filters - Filters to set
   */
  function setActiveFilters(filters) {
    state.activeFilters = JSON.parse(JSON.stringify(filters));
    applyFiltersToUI();
    updateUrl();
    saveFiltersToStorage();

    emitEvent('filterChange', { filters: state.activeFilters });
    debouncedTriggerSearch();
  }

  /**
   * Clear all filters
   */
  function clearAllFilters() {
    state.activeFilters = {};
    applyFiltersToUI();
    updateUrl();
    saveFiltersToStorage();

    emitEvent('filterChange', { filters: state.activeFilters, cleared: true });
    triggerSearch();
  }

  // ===================================================================
  // UI STATE SYNCHRONIZATION
  // ===================================================================

  /**
   * Apply current filter state to UI
   */
  function applyFiltersToUI() {
    const chips = document.querySelectorAll('.filter-chip');

    chips.forEach(chip => {
      const filterType = chip.dataset.filterType;
      const filterValue = chip.dataset.filterValue;
      const isActive = isFilterActive(filterType, filterValue);

      // Update visual state
      if (isActive) {
        chip.classList.add('active');
        chip.setAttribute('aria-pressed', 'true');
      } else {
        chip.classList.remove('active');
        chip.setAttribute('aria-pressed', 'false');
      }
    });

    // Update clear button visibility
    updateClearButtonVisibility();

    // Update results info
    updateResultsInfo();
  }

  /**
   * Update clear button visibility
   */
  function updateClearButtonVisibility() {
    const clearButton = document.querySelector('.filters-clear-all');
    if (!clearButton) return;

    const hasActiveFilters = Object.keys(state.activeFilters).length > 0;
    if (hasActiveFilters) {
      clearButton.style.display = '';
      clearButton.removeAttribute('disabled');
    } else {
      clearButton.style.display = 'none';
      clearButton.setAttribute('disabled', 'disabled');
    }
  }

  /**
   * Update results information display
   */
  function updateResultsInfo() {
    const infoElement = document.querySelector('.filters-results-info');
    if (!infoElement) return;

    const filterCount = Object.values(state.activeFilters).reduce(
      (sum, values) => sum + values.length,
      0
    );

    if (filterCount === 0) {
      infoElement.textContent = '';
      infoElement.style.display = 'none';
    } else {
      infoElement.textContent = `${filterCount} filter${filterCount !== 1 ? 's' : ''} applied`;
      infoElement.style.display = '';
    }
  }

  // ===================================================================
  // CATEGORY DROPDOWN
  // ===================================================================

  /**
   * Setup category dropdown functionality
   */
  function setupCategoryDropdown() {
    const dropdown = document.querySelector('.category-dropdown-container');
    if (!dropdown) return;

    const trigger = dropdown.querySelector('.category-dropdown-trigger');
    const menu = dropdown.querySelector('.category-dropdown-menu');

    if (!trigger || !menu) return;

    // Toggle dropdown on click
    trigger.addEventListener('click', event => {
      event.preventDefault();
      event.stopPropagation();
      toggleCategoryDropdown();
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', event => {
      if (!dropdown.contains(event.target)) {
        closeCategoryDropdown();
      }
    });

    // Handle category item clicks
    const items = menu.querySelectorAll('.category-dropdown-item');
    items.forEach(item => {
      item.addEventListener('click', event => {
        event.preventDefault();
        handleCategorySelect(item);
      });
    });

    // Keyboard navigation in dropdown
    setupDropdownKeyboardNavigation(menu, items);
  }

  /**
   * Toggle category dropdown open/closed
   */
  function toggleCategoryDropdown() {
    if (state.categoryDropdownOpen) {
      closeCategoryDropdown();
    } else {
      openCategoryDropdown();
    }
  }

  /**
   * Open category dropdown
   */
  function openCategoryDropdown() {
    const dropdown = document.querySelector('.category-dropdown-container');
    if (!dropdown) return;

    state.categoryDropdownOpen = true;
    dropdown.classList.add('open');

    const trigger = dropdown.querySelector('.category-dropdown-trigger');
    trigger.setAttribute('aria-expanded', 'true');

    const firstItem = dropdown.querySelector('.category-dropdown-item');
    if (firstItem) {
      firstItem.focus();
    }

    emitEvent('dropdownOpen', {});
  }

  /**
   * Close category dropdown
   */
  function closeCategoryDropdown() {
    const dropdown = document.querySelector('.category-dropdown-container');
    if (!dropdown) return;

    state.categoryDropdownOpen = false;
    dropdown.classList.remove('open');

    const trigger = dropdown.querySelector('.category-dropdown-trigger');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.focus();

    emitEvent('dropdownClose', {});
  }

  /**
   * Handle category selection
   * @param {HTMLElement} item - Selected category item
   */
  function handleCategorySelect(item) {
    const categoryValue = item.dataset.categoryValue;
    if (!categoryValue) return;

    state.selectedCategory = categoryValue;

    // Add filter
    addFilter('category', categoryValue);
    applyFiltersToUI();
    updateUrl();
    saveFiltersToStorage();

    // Update dropdown visual state
    const items = document.querySelectorAll('.category-dropdown-item');
    items.forEach(i => {
      if (i === item) {
        i.classList.add('selected');
        i.setAttribute('aria-selected', 'true');
      } else {
        i.classList.remove('selected');
        i.setAttribute('aria-selected', 'false');
      }
    });

    // Close dropdown
    closeCategoryDropdown();

    // Trigger events
    emitEvent('filterChange', {
      filterType: 'category',
      filterValue: categoryValue,
      isActive: true,
    });

    debouncedTriggerSearch();
  }

  /**
   * Setup keyboard navigation for dropdown
   * @param {HTMLElement} menu - Dropdown menu element
   * @param {NodeList} items - Dropdown items
   */
  function setupDropdownKeyboardNavigation(menu, items) {
    menu.addEventListener('keydown', event => {
      const currentItem = document.activeElement;
      let nextItem = null;

      switch (event.key) {
        case 'ArrowDown':
          event.preventDefault();
          nextItem = currentItem.nextElementSibling;
          if (!nextItem) nextItem = items[0];
          if (nextItem) nextItem.focus();
          break;

        case 'ArrowUp':
          event.preventDefault();
          nextItem = currentItem.previousElementSibling;
          if (!nextItem) nextItem = items[items.length - 1];
          if (nextItem) nextItem.focus();
          break;

        case 'Enter':
          event.preventDefault();
          if (currentItem.classList.contains('category-dropdown-item')) {
            handleCategorySelect(currentItem);
          }
          break;

        case 'Escape':
          event.preventDefault();
          closeCategoryDropdown();
          break;
      }
    });
  }

  // ===================================================================
  // CLEAR ALL BUTTON
  // ===================================================================

  /**
   * Setup clear all button
   */
  function setupClearAllButton() {
    const clearButton = document.querySelector('.filters-clear-all');
    if (!clearButton) return;

    clearButton.addEventListener('click', event => {
      event.preventDefault();
      clearAllFilters();
    });
  }

  // ===================================================================
  // KEYBOARD NAVIGATION
  // ===================================================================

  /**
   * Setup keyboard navigation for filter chips
   */
  function setupKeyboardNavigation() {
    const container = document.querySelector('.filter-chips-container');
    if (!container) return;

    container.addEventListener('keydown', event => {
      const chip = event.target.closest('.filter-chip');
      if (!chip) return;

      switch (event.key) {
        case ' ':
        case 'Enter':
          event.preventDefault();
          handleToggleChip(chip);
          break;

        case 'Delete':
        case 'Backspace':
          event.preventDefault();
          handleRemoveChip(chip);
          break;

        case 'ArrowRight':
          event.preventDefault();
          const nextChip = chip.nextElementSibling;
          if (nextChip && nextChip.classList.contains('filter-chip')) {
            nextChip.focus();
          }
          break;

        case 'ArrowLeft':
          event.preventDefault();
          const prevChip = chip.previousElementSibling;
          if (prevChip && prevChip.classList.contains('filter-chip')) {
            prevChip.focus();
          }
          break;
      }
    });

    // Make chips keyboard accessible
    const chips = container.querySelectorAll('.filter-chip');
    chips.forEach((chip, index) => {
      chip.setAttribute('role', 'button');
      chip.setAttribute('tabindex', index === 0 ? '0' : '-1');
      chip.setAttribute('aria-pressed', 'false');
    });
  }

  // ===================================================================
  // SEARCH TRIGGERING
  // ===================================================================

  /**
   * Debounced search trigger
   */
  function debouncedTriggerSearch() {
    if (state.debounceTimer) {
      clearTimeout(state.debounceTimer);
    }
    state.debounceTimer = setTimeout(triggerSearch, CONFIG.debounceDelay);
  }

  /**
   * Trigger search with current filters
   */
  function triggerSearch() {
    emitEvent('filterApply', {
      filters: state.activeFilters,
    });
  }

  // ===================================================================
  // EVENT SYSTEM
  // ===================================================================

  /**
   * Emit an event to registered listeners
   * @param {string} eventType - Type of event
   * @param {Object} data - Event data
   */
  function emitEvent(eventType, data) {
    const listeners = state.eventListeners[eventType] || [];
    listeners.forEach(callback => {
      try {
        callback(data);
      } catch (e) {
        console.error(`Error in ${eventType} listener:`, e);
      }
    });
  }

  /**
   * Register event listener
   * @param {string} eventType - Type of event to listen for
   * @param {Function} callback - Callback function
   */
  function addEventListener(eventType, callback) {
    if (!state.eventListeners[eventType]) {
      state.eventListeners[eventType] = [];
    }
    state.eventListeners[eventType].push(callback);
  }

  // ===================================================================
  // PUBLIC API
  // ===================================================================

  window.FilterChips = {
    init,
    getFilters: getActiveFilters,
    setFilters: setActiveFilters,
    clearAll: clearAllFilters,
    on: addEventListener,
    addFilter,
    removeFilter,
    isFilterActive,
  };

  // Auto-initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      init({ loadFromUrl: true, persistToStorage: true });
    });
  } else {
    init({ loadFromUrl: true, persistToStorage: true });
  }

})();
