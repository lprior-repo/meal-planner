/**
 * Filter Integration - Bridges FilterStateManager with Dashboard Filters
 *
 * Integrates the advanced filter state manager with the existing dashboard
 * filter UI, providing:
 * - Automatic state synchronization
 * - Enhanced UI controls (clear all, export, import)
 * - Visual feedback for active filters
 * - Keyboard shortcuts (Ctrl+Z for undo, Ctrl+Y for redo)
 *
 * Dependencies: filter-state-manager.js, dashboard-filters.js
 */

(function() {
  'use strict';

  // ===================================================================
  // CONFIGURATION
  // ===================================================================

  const CONFIG = {
    enableKeyboardShortcuts: true,
    enableFilterBadge: true,
    enableClearButton: true,
    enableExportButton: true,
    enableHistoryButtons: true,
    showFilterDescription: true,
  };

  // ===================================================================
  // INITIALIZATION
  // ===================================================================

  /**
   * Initialize filter integration
   * Waits for both FilterStateManager and DashboardFilters to be available
   */
  function init() {
    // Wait for dependencies
    if (!window.FilterStateManager) {
      console.warn('[FilterIntegration] FilterStateManager not found, retrying...');
      setTimeout(init, 100);
      return;
    }

    // Initialize FilterStateManager with dashboard-specific config
    window.FilterStateManager.init({
      storageType: 'sessionStorage',
      enableUrlSync: true,
      enableHistory: true,
      persistAcrossSessions: false,
    });

    // Setup UI integration
    setupStateChangeListeners();
    setupUIControls();
    setupKeyboardShortcuts();

    // Enhance filter controls
    enhanceFilterUI();

    console.log('[FilterIntegration] Initialized successfully');
  }

  // ===================================================================
  // STATE CHANGE LISTENERS
  // ===================================================================

  /**
   * Setup listeners for state changes
   */
  function setupStateChangeListeners() {
    // Listen for filter state changes
    window.FilterStateManager.onStateChange((event) => {
      // Trigger dashboard filter update if it exists
      if (window.DashboardFilters) {
        const newState = event.state;
        window.DashboardFilters.setFilters(newState);
      }

      // Update visual indicators
      updateFilterIndicators(event.state);

      // Log state change
      if (process.env && process.env.DEBUG) {
        console.log('[FilterIntegration] State changed:', event);
      }
    });

    // Listen for history changes
    window.FilterStateManager.onHistoryChange((event) => {
      updateHistoryButtons(event);
    });

    // Listen for errors
    window.FilterStateManager.onError((event) => {
      console.error('[FilterIntegration] Error:', event.error);
      showErrorNotification(event.message || 'Filter operation failed');
    });
  }

  // ===================================================================
  // UI CONTROLS
  // ===================================================================

  /**
   * Setup enhanced UI controls
   */
  function setupUIControls() {
    // Create and inject control panel
    const controlPanel = createControlPanel();
    const filterSection = document.querySelector('.meal-filters');

    if (filterSection && controlPanel) {
      // Insert after filter buttons
      const filterButtons = filterSection.querySelector('.filter-buttons');
      if (filterButtons) {
        filterButtons.after(controlPanel);
      } else {
        filterSection.appendChild(controlPanel);
      }
    }
  }

  /**
   * Create filter control panel with buttons
   * @returns {HTMLElement} Control panel element
   */
  function createControlPanel() {
    const panel = document.createElement('div');
    panel.className = 'filter-controls-panel';
    panel.setAttribute('role', 'group');
    panel.setAttribute('aria-label', 'Filter controls');

    let html = '';

    // Filter description (badge)
    if (CONFIG.enableFilterBadge || CONFIG.showFilterDescription) {
      html += `
        <div class="filter-status" id="filter-status" role="status" aria-live="polite">
          <span class="filter-description" id="filter-description"></span>
          <span class="filter-badge" id="filter-badge" style="display: none;">
            <span class="filter-badge-count">0</span>
          </span>
        </div>
      `;
    }

    // Control buttons container
    html += '<div class="filter-buttons-secondary">';

    // Undo/Redo buttons (history)
    if (CONFIG.enableHistoryButtons) {
      html += `
        <button id="filter-undo" class="filter-btn-secondary filter-btn-undo"
                title="Undo (Ctrl+Z)" disabled aria-label="Undo filter changes">
          <span class="btn-icon">↶</span>
        </button>
        <button id="filter-redo" class="filter-btn-secondary filter-btn-redo"
                title="Redo (Ctrl+Y)" disabled aria-label="Redo filter changes">
          <span class="btn-icon">↷</span>
        </button>
      `;
    }

    // Clear all filters button
    if (CONFIG.enableClearButton) {
      html += `
        <button id="filter-clear-all" class="filter-btn-secondary filter-btn-clear"
                title="Clear all filters" aria-label="Clear all active filters">
          <span class="btn-icon">✕</span>
          <span class="btn-text">Clear Filters</span>
        </button>
      `;
    }

    // Export/Import buttons
    if (CONFIG.enableExportButton) {
      html += `
        <button id="filter-export" class="filter-btn-secondary filter-btn-export"
                title="Export filters as URL" aria-label="Export current filters">
          <span class="btn-icon">📤</span>
        </button>
        <button id="filter-import" class="filter-btn-secondary filter-btn-import"
                title="Import filters" aria-label="Import filters from URL or JSON">
          <span class="btn-icon">📥</span>
        </button>
      `;
    }

    html += '</div>';

    panel.innerHTML = html;

    // Attach event listeners
    attachControlListeners(panel);

    return panel;
  }

  /**
   * Attach event listeners to control buttons
   * @param {HTMLElement} panel - Control panel element
   */
  function attachControlListeners(panel) {
    const undoBtn = panel.querySelector('#filter-undo');
    const redoBtn = panel.querySelector('#filter-redo');
    const clearBtn = panel.querySelector('#filter-clear-all');
    const exportBtn = panel.querySelector('#filter-export');
    const importBtn = panel.querySelector('#filter-import');

    if (undoBtn) {
      undoBtn.addEventListener('click', (e) => {
        e.preventDefault();
        window.FilterStateManager.undo();
      });
    }

    if (redoBtn) {
      redoBtn.addEventListener('click', (e) => {
        e.preventDefault();
        window.FilterStateManager.redo();
      });
    }

    if (clearBtn) {
      clearBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const confirmed = confirm('Clear all filters?');
        if (confirmed) {
          window.FilterStateManager.reset();
        }
      });
    }

    if (exportBtn) {
      exportBtn.addEventListener('click', (e) => {
        e.preventDefault();
        exportFilters();
      });
    }

    if (importBtn) {
      importBtn.addEventListener('click', (e) => {
        e.preventDefault();
        importFilters();
      });
    }
  }

  // ===================================================================
  // KEYBOARD SHORTCUTS
  // ===================================================================

  /**
   * Setup keyboard shortcuts
   */
  function setupKeyboardShortcuts() {
    if (!CONFIG.enableKeyboardShortcuts) return;

    document.addEventListener('keydown', (event) => {
      // Only trigger if not typing in an input
      if (event.target.matches('input, textarea, [contenteditable]')) {
        return;
      }

      // Ctrl+Z / Cmd+Z: Undo
      if ((event.ctrlKey || event.metaKey) && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        window.FilterStateManager.undo();
        showNotification('Filter undo');
      }

      // Ctrl+Y / Cmd+Shift+Z: Redo
      if ((event.ctrlKey || event.metaKey) && (event.key === 'y' || (event.key === 'z' && event.shiftKey))) {
        event.preventDefault();
        window.FilterStateManager.redo();
        showNotification('Filter redo');
      }

      // Ctrl+Shift+F: Focus filter controls
      if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key === 'f') {
        event.preventDefault();
        const firstFilterBtn = document.querySelector('[data-filter-meal-type]');
        if (firstFilterBtn) {
          firstFilterBtn.focus();
          showNotification('Focus filter controls');
        }
      }

      // Ctrl+Alt+C: Clear all filters
      if ((event.ctrlKey || event.metaKey) && event.altKey && event.key === 'c') {
        event.preventDefault();
        window.FilterStateManager.reset();
        showNotification('All filters cleared');
      }
    });
  }

  // ===================================================================
  // VISUAL UPDATES
  // ===================================================================

  /**
   * Update filter status indicators
   * @param {Object} state - Current filter state
   */
  function updateFilterIndicators(state) {
    const description = window.FilterStateManager.getFilterDescription();
    const hasFilters = window.FilterStateManager.hasActiveFilters();

    // Update description
    const descElement = document.getElementById('filter-description');
    if (descElement) {
      descElement.textContent = description;
    }

    // Update badge visibility
    const badge = document.getElementById('filter-badge');
    if (badge) {
      if (hasFilters) {
        badge.style.display = 'inline-block';
        const count = Object.values(state).filter(v => v && v !== 'all').length;
        badge.querySelector('.filter-badge-count').textContent = count;
      } else {
        badge.style.display = 'none';
      }
    }

    // Update clear button visibility
    const clearBtn = document.getElementById('filter-clear-all');
    if (clearBtn) {
      clearBtn.style.display = hasFilters ? 'inline-flex' : 'none';
    }
  }

  /**
   * Update history button states
   * @param {Object} historyInfo - History information
   */
  function updateHistoryButtons(historyInfo) {
    const undoBtn = document.getElementById('filter-undo');
    const redoBtn = document.getElementById('filter-redo');

    if (undoBtn) {
      undoBtn.disabled = !historyInfo.canUndo;
    }

    if (redoBtn) {
      redoBtn.disabled = !historyInfo.canRedo;
    }
  }

  /**
   * Enhance existing filter UI
   * Add labels and ARIA attributes to existing buttons
   */
  function enhanceFilterUI() {
    const filterButtons = document.querySelectorAll('[data-filter-meal-type]');

    filterButtons.forEach(btn => {
      // Update ARIA pressed state based on current state
      const mealType = btn.dataset.filterMealType;
      const currentState = window.FilterStateManager.getState();
      const isActive = mealType === currentState.mealType;

      btn.setAttribute('aria-pressed', isActive ? 'true' : 'false');

      // Add keyboard shortcut hints to title
      const shortcuts = {
        'all': 'All meals',
        'breakfast': 'Breakfast only (B)',
        'lunch': 'Lunch only (L)',
        'dinner': 'Dinner only (D)',
        'snack': 'Snacks only (S)',
      };

      btn.title = shortcuts[mealType] || mealType;

      // Add numeric shortcuts
      if (mealType !== 'all') {
        btn.addEventListener('keydown', (e) => {
          if (e.key === mealType[0].toUpperCase()) {
            btn.click();
          }
        });
      }
    });

    // Update filter section role and label
    const filterSection = document.querySelector('.meal-filters');
    if (filterSection && !filterSection.getAttribute('aria-describedby')) {
      filterSection.setAttribute('aria-describedby', 'filter-description');
    }
  }

  // ===================================================================
  // EXPORT/IMPORT FUNCTIONS
  // ===================================================================

  /**
   * Export filters
   * Offers URL or JSON download
   */
  function exportFilters() {
    const url = window.FilterStateManager.exportAsUrl();

    // Create modal dialog
    const modal = document.createElement('div');
    modal.className = 'filter-export-modal';
    modal.innerHTML = `
      <div class="modal-content">
        <div class="modal-header">
          <h3>Export Filters</h3>
          <button class="modal-close" aria-label="Close">&times;</button>
        </div>
        <div class="modal-body">
          <p>Share or bookmark this URL with your current filters:</p>
          <div class="export-url">
            <input type="text" readonly value="${escapeHtml(url)}"
                   class="export-input" id="export-url-input">
            <button class="btn-copy-url" title="Copy to clipboard">Copy</button>
          </div>
          <hr>
          <details>
            <summary>Or download as JSON</summary>
            <button class="btn-download-json">Download JSON</button>
          </details>
        </div>
      </div>
    `;

    document.body.appendChild(modal);

    // Close button
    modal.querySelector('.modal-close').addEventListener('click', () => {
      modal.remove();
    });

    // Copy button
    modal.querySelector('.btn-copy-url').addEventListener('click', () => {
      const input = modal.querySelector('#export-url-input');
      input.select();
      document.execCommand('copy');
      showNotification('URL copied to clipboard');
    });

    // Download JSON
    modal.querySelector('.btn-download-json').addEventListener('click', () => {
      const json = window.FilterStateManager.exportState();
      const blob = new Blob([json], { type: 'application/json' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = `meal-planner-filters-${new Date().toISOString().split('T')[0]}.json`;
      link.click();
      showNotification('Filters downloaded');
    });

    // Click outside to close
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.remove();
      }
    });
  }

  /**
   * Import filters from URL or JSON
   */
  function importFilters() {
    const modal = document.createElement('div');
    modal.className = 'filter-import-modal';
    modal.innerHTML = `
      <div class="modal-content">
        <div class="modal-header">
          <h3>Import Filters</h3>
          <button class="modal-close" aria-label="Close">&times;</button>
        </div>
        <div class="modal-body">
          <p>Paste filter JSON or share URL:</p>
          <textarea id="import-input" class="import-textarea"
                    placeholder="Paste JSON here or share the URL with filters..."></textarea>
          <button class="btn-import-submit">Import</button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);

    // Close button
    modal.querySelector('.modal-close').addEventListener('click', () => {
      modal.remove();
    });

    // Import button
    modal.querySelector('.btn-import-submit').addEventListener('click', () => {
      const input = modal.querySelector('#import-input').value;

      // Try to parse as JSON first
      if (window.FilterStateManager.importState(input)) {
        showNotification('Filters imported successfully');
        modal.remove();
        return;
      }

      // Try to extract filters from URL
      try {
        const url = new URL(input);
        const params = new URLSearchParams(url.search);
        const extracted = {};

        for (const [key, value] of params.entries()) {
          if (key.startsWith('filter-')) {
            const filterName = key.substring(7); // Remove 'filter-' prefix
            extracted[filterName] = value;
          }
        }

        if (Object.keys(extracted).length > 0) {
          window.FilterStateManager.setState(extracted);
          showNotification('Filters imported from URL');
          modal.remove();
          return;
        }
      } catch (e) {
        // Not a valid URL, ignore
      }

      showErrorNotification('Invalid JSON or URL');
    });

    // Click outside to close
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.remove();
      }
    });

    // Auto-focus textarea
    modal.querySelector('#import-input').focus();
  }

  // ===================================================================
  // NOTIFICATIONS
  // ===================================================================

  /**
   * Show notification message
   * @param {string} message - Message to display
   * @param {string} type - Type: 'info', 'success', 'error'
   */
  function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `filter-notification filter-notification-${type}`;
    notification.textContent = message;
    notification.setAttribute('role', 'alert');

    document.body.appendChild(notification);

    // Auto-remove after 3 seconds
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }

  /**
   * Show error notification
   * @param {string} message - Error message
   */
  function showErrorNotification(message) {
    showNotification(message, 'error');
  }

  /**
   * HTML escape utility
   * @param {string} text - Text to escape
   * @returns {string} Escaped HTML
   */
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ===================================================================
  // INITIALIZATION
  // ===================================================================

  // Auto-initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Export for testing
  window.FilterIntegration = {
    init,
    exportFilters,
    importFilters,
  };
})();
