/**
 * Food Search Filter Management
 *
 * Handles:
 * - Removing individual filters
 * - Clearing all filters
 * - Real-time result count updates
 * - Filter state management
 */

class FoodSearchFilters {
  constructor() {
    this.activeFilters = new Map();
    this.setupEventListeners();
  }

  /**
   * Setup event listeners for filter operations
   */
  setupEventListeners() {
    // Remove individual filter tag
    document.addEventListener('click', (e) => {
      if (e.target.closest('.filter-tag')) {
        const filterTag = e.target.closest('.filter-tag');
        const filterName = filterTag.dataset.filterName;
        const filterValue = filterTag.dataset.filterValue;

        if (filterName && filterValue) {
          this.removeFilter(filterName, filterValue);
        }
      }

      // Clear all filters
      if (e.target.closest('.btn-clear-all-filters')) {
        this.clearAllFilters();
      }
    });
  }

  /**
   * Remove a single filter and trigger search update
   * @param {string} filterName - The filter name (e.g., "category", "verified")
   * @param {string} filterValue - The filter value to remove
   */
  removeFilter(filterName, filterValue) {
    const key = `${filterName}:${filterValue}`;
    this.activeFilters.delete(key);
    this.triggerSearch();
    this.announceFilterRemoval(filterValue);
  }

  /**
   * Clear all active filters and trigger search update
   */
  clearAllFilters() {
    this.activeFilters.clear();
    this.triggerSearch();
    this.announceFilterClear();
  }

  /**
   * Add filter to active filters map
   * @param {string} filterName - The filter name
   * @param {string} filterValue - The filter value
   */
  addFilter(filterName, filterValue) {
    const key = `${filterName}:${filterValue}`;
    this.activeFilters.set(key, { name: filterName, value: filterValue });
  }

  /**
   * Get all active filters as object
   * @returns {Object} Object with filter names as keys and values as values
   */
  getActiveFiltersObject() {
    const result = {};
    this.activeFilters.forEach(({ name, value }) => {
      result[name] = value;
    });
    return result;
  }

  /**
   * Trigger new search with current filters
   * Dispatches custom event for search handler
   */
  triggerSearch() {
    const filters = this.getActiveFiltersObject();
    const searchInput = document.querySelector('.input-search');
    const query = searchInput?.value || '';

    const event = new CustomEvent('foodSearchFilterChange', {
      detail: {
        query,
        filters,
        timestamp: Date.now()
      }
    });
    document.dispatchEvent(event);
  }

  /**
   * Announce filter removal to screen readers
   * @param {string} filterValue - The removed filter value
   */
  announceFilterRemoval(filterValue) {
    const announcement = document.createElement('div');
    announcement.className = 'sr-only';
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.textContent = `${filterValue} filter removed`;

    document.body.appendChild(announcement);
    setTimeout(() => announcement.remove(), 1000);
  }

  /**
   * Announce filter clear to screen readers
   */
  announceFilterClear() {
    const announcement = document.createElement('div');
    announcement.className = 'sr-only';
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.textContent = 'All filters cleared';

    document.body.appendChild(announcement);
    setTimeout(() => announcement.remove(), 1000);
  }

  /**
   * Update the result count display
   * @param {number} count - Number of results
   */
  updateResultCount(count) {
    const countElement = document.querySelector('.search-results-count');
    if (countElement) {
      const text = count === 1 ? '1 result' : `${count} results`;
      countElement.textContent = text;
    }
  }
}

// Initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.foodSearchFilters = new FoodSearchFilters();
  });
} else {
  window.foodSearchFilters = new FoodSearchFilters();
}

/**
 * Integration Example for Search Handler
 *
 * In your main search handler:
 *
 * function handleSearch(query) {
 *   const filters = window.foodSearchFilters.getActiveFiltersObject();
 *
 *   fetch('/api/food-search', {
 *     method: 'POST',
 *     body: JSON.stringify({ query, filters })
 *   })
 *   .then(res => res.json())
 *   .then(data => {
 *     window.foodSearchFilters.updateResultCount(data.results.length);
 *     renderResults(data.results);
 *   });
 * }
 *
 * // Listen for filter changes
 * document.addEventListener('foodSearchFilterChange', (e) => {
 *   handleSearch(e.detail.query);
 * });
 */
