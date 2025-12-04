/**
 * Mobile-Responsive Filter Panel
 *
 * Handles collapsible filter panel functionality on mobile devices.
 * Features:
 * - Toggle filter panel visibility on mobile
 * - Smooth expand/collapse animations
 * - Keyboard accessibility (Enter/Space)
 * - Touch-friendly interactions
 * - Remembers user preference (localStorage)
 */

(function() {
  'use strict';

  const FILTER_EXPANDED_KEY = 'meal-filters-expanded';
  const MOBILE_BREAKPOINT = 640;

  class FilterPanel {
    constructor() {
      this.filterToggle = document.querySelector('.filter-toggle');
      this.filterButtons = document.querySelector('.filter-buttons');
      this.mealFilters = document.querySelector('.meal-filters');

      if (!this.filterToggle || !this.filterButtons) {
        console.warn('Filter panel elements not found');
        return;
      }

      this.isExpanded = this.getStoredState();
      this.init();
    }

    /**
     * Initialize event listeners and set initial state
     */
    init() {
      // Event listeners
      if (this.filterToggle) {
        this.filterToggle.addEventListener('click', () => this.toggle());
        this.filterToggle.addEventListener('keydown', (e) => this.handleKeydown(e));
      }

      // Set initial state based on viewport
      this.updateState();
      window.addEventListener('resize', () => this.updateState());

      // Filter button interactions
      this.setupFilterButtons();
    }

    /**
     * Setup filter button event listeners
     */
    setupFilterButtons() {
      const buttons = this.filterButtons.querySelectorAll('.filter-btn');
      buttons.forEach(button => {
        button.addEventListener('click', (e) => this.handleFilterClick(e));
        button.addEventListener('keydown', (e) => this.handleFilterKeydown(e));
      });
    }

    /**
     * Toggle filter panel visibility
     */
    toggle() {
      const isNowExpanded = !this.isExpanded;
      this.setExpanded(isNowExpanded);
    }

    /**
     * Set expanded state and update UI
     */
    setExpanded(expanded) {
      this.isExpanded = expanded;
      this.saveState();
      this.updateUI();

      // Announce change to screen readers
      this.announceChange(expanded);
    }

    /**
     * Update visual state based on expanded status
     */
    updateUI() {
      if (this.filterToggle) {
        this.filterToggle.setAttribute('aria-expanded', this.isExpanded);
        this.filterToggle.classList.toggle('expanded', this.isExpanded);
      }

      if (this.filterButtons) {
        this.filterButtons.classList.toggle('expanded', this.isExpanded);
      }

      // Focus management
      if (this.isExpanded && this.filterButtons) {
        // Focus first filter button when expanding
        const firstButton = this.filterButtons.querySelector('.filter-btn');
        if (firstButton) {
          setTimeout(() => firstButton.focus(), 100);
        }
      }
    }

    /**
     * Update state based on viewport size
     */
    updateState() {
      const isMobile = window.innerWidth < MOBILE_BREAKPOINT;

      if (!isMobile && this.isExpanded) {
        // Auto-expand on larger screens
        this.setExpanded(true);
      } else if (isMobile && !this.isExpanded) {
        // Respect user's choice on mobile
        this.updateUI();
      } else {
        this.updateUI();
      }
    }

    /**
     * Handle keyboard interactions on toggle button
     */
    handleKeydown(e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.toggle();
      }
    }

    /**
     * Handle filter button clicks
     */
    handleFilterClick(e) {
      const button = e.target.closest('.filter-btn');
      if (!button) return;

      // Update active state
      const buttons = this.filterButtons.querySelectorAll('.filter-btn');
      buttons.forEach(btn => btn.classList.remove('active'));
      button.classList.add('active');
      button.setAttribute('aria-pressed', 'true');

      // Announce filter change
      const filterType = button.getAttribute('data-filter-meal-type');
      this.announceFilter(filterType);

      // Emit custom event for other scripts
      this.mealFilters.dispatchEvent(new CustomEvent('filter:changed', {
        detail: { filterType },
        bubbles: true
      }));
    }

    /**
     * Handle keyboard navigation within filters
     */
    handleFilterKeydown(e) {
      const buttons = Array.from(this.filterButtons.querySelectorAll('.filter-btn'));
      const currentIndex = buttons.indexOf(e.target.closest('.filter-btn'));

      if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
        e.preventDefault();
        const nextButton = buttons[currentIndex + 1];
        if (nextButton) nextButton.focus();
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
        e.preventDefault();
        const prevButton = buttons[currentIndex - 1];
        if (prevButton) prevButton.focus();
      } else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.handleFilterClick({ target: e.target });
      }
    }

    /**
     * Get stored expansion state from localStorage
     */
    getStoredState() {
      const isMobile = window.innerWidth < MOBILE_BREAKPOINT;
      if (!isMobile) return true; // Always expanded on non-mobile

      try {
        const stored = localStorage.getItem(FILTER_EXPANDED_KEY);
        return stored === null ? true : stored === 'true';
      } catch (e) {
        console.warn('localStorage not available:', e);
        return true;
      }
    }

    /**
     * Save expansion state to localStorage
     */
    saveState() {
      try {
        localStorage.setItem(FILTER_EXPANDED_KEY, this.isExpanded);
      } catch (e) {
        console.warn('Failed to save filter state:', e);
      }
    }

    /**
     * Announce state change to screen readers
     */
    announceChange(expanded) {
      const announcement = expanded ? 'Filter panel expanded' : 'Filter panel collapsed';
      this.announceToScreenReader(announcement);
    }

    /**
     * Announce filter selection to screen readers
     */
    announceFilter(filterType) {
      const filterLabel = filterType.charAt(0).toUpperCase() + filterType.slice(1);
      this.announceToScreenReader(`Showing ${filterLabel} meals`);
    }

    /**
     * Announce message to screen readers
     */
    announceToScreenReader(message) {
      const announcement = document.getElementById('filter-announcement');
      if (announcement) {
        announcement.textContent = message;
      }
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      new FilterPanel();
    });
  } else {
    new FilterPanel();
  }

  // Export for testing
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = FilterPanel;
  }
})();
