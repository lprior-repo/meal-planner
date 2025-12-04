/**
 * Lazy Loading Manager
 *
 * Handles progressive loading of components and images using:
 * - Intersection Observer API for viewport detection
 * - Virtual scrolling for long lists
 * - Deferred component rendering
 * - Progressive image loading
 *
 * Performance optimizations:
 * - Loads content only when needed
 * - Reduces initial page weight
 * - Improves Time to Interactive (TTI)
 * - Reduces Cumulative Layout Shift (CLS)
 */

(function() {
  'use strict';

  // ===================================================================
  // CONFIGURATION
  // ===================================================================

  const CONFIG = {
    rootMargin: '50px 0px', // Start loading 50px before entering viewport
    threshold: 0.01, // Trigger when 1% visible
    imageRootMargin: '200px 0px', // Preload images 200px before viewport
    virtualScrollBuffer: 5, // Extra items to render above/below viewport
  };

  // ===================================================================
  // INTERSECTION OBSERVER SETUP
  // ===================================================================

  let lazyObserver = null;
  let imageObserver = null;
  let componentObserver = null;

  /**
   * Initialize all lazy loading observers
   */
  function initLazyLoading() {
    if (!('IntersectionObserver' in window)) {
      console.warn('IntersectionObserver not supported, falling back to eager loading');
      loadAllEagerly();
      return;
    }

    // Observer for lazy sections
    lazyObserver = new IntersectionObserver(handleLazySectionIntersection, {
      rootMargin: CONFIG.rootMargin,
      threshold: CONFIG.threshold
    });

    // Observer for lazy images
    imageObserver = new IntersectionObserver(handleImageIntersection, {
      rootMargin: CONFIG.imageRootMargin,
      threshold: 0
    });

    // Observer for deferred components
    componentObserver = new IntersectionObserver(handleComponentIntersection, {
      rootMargin: CONFIG.rootMargin,
      threshold: CONFIG.threshold
    });

    // Observe all lazy elements
    observeLazyElements();

    // Setup virtual scrolling
    initVirtualScrolling();
  }

  /**
   * Find and observe all lazy-loadable elements
   */
  function observeLazyElements() {
    // Lazy sections
    document.querySelectorAll('[data-lazy-load="true"]').forEach(el => {
      if (el.dataset.loaded !== 'true') {
        lazyObserver.observe(el);
      }
    });

    // Lazy images
    document.querySelectorAll('img.lazy-image').forEach(img => {
      if (!img.src || img.dataset.src) {
        imageObserver.observe(img);
      }
    });

    // Deferred components
    document.querySelectorAll('.deferred-component').forEach(el => {
      if (el.dataset.rendered !== 'true') {
        componentObserver.observe(el);
      }
    });
  }

  // ===================================================================
  // LAZY SECTION LOADING
  // ===================================================================

  /**
   * Handle lazy section entering viewport
   */
  function handleLazySectionIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const section = entry.target;
        if (section.dataset.loaded !== 'true') {
          loadLazySection(section);
          lazyObserver.unobserve(section);
        }
      }
    });
  }

  /**
   * Load content for a lazy section
   */
  async function loadLazySection(section) {
    const contentSrc = section.dataset.contentSrc;
    const placeholder = section.querySelector('[data-placeholder="true"]');
    const contentContainer = section.querySelector('.lazy-content');

    if (!contentSrc || !contentContainer) return;

    try {
      // Fetch content
      const response = await fetch(contentSrc);
      if (!response.ok) throw new Error('Failed to load content');

      const html = await response.text();

      // Fade out placeholder
      if (placeholder) {
        placeholder.style.opacity = '0';
        placeholder.style.transition = 'opacity 0.3s';
      }

      // Wait for fade, then swap content
      setTimeout(() => {
        if (placeholder) placeholder.remove();
        contentContainer.innerHTML = html;
        contentContainer.style.display = 'block';
        contentContainer.style.opacity = '0';
        contentContainer.style.transition = 'opacity 0.3s';

        // Trigger reflow
        void contentContainer.offsetWidth;

        // Fade in content
        contentContainer.style.opacity = '1';

        section.dataset.loaded = 'true';

        // Dispatch custom event
        section.dispatchEvent(new CustomEvent('lazyloaded', {
          detail: { section }
        }));
      }, 300);

    } catch (error) {
      console.error('Error loading lazy section:', error);
      if (placeholder) {
        placeholder.innerHTML = '<p class="error">Failed to load content</p>';
      }
    }
  }

  // ===================================================================
  // LAZY IMAGE LOADING
  // ===================================================================

  /**
   * Handle image entering viewport
   */
  function handleImageIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        loadLazyImage(img);
        imageObserver.unobserve(img);
      }
    });
  }

  /**
   * Load a lazy image
   */
  function loadLazyImage(img) {
    const src = img.dataset.src;
    if (!src) return;

    const wrapper = img.closest('.lazy-image-wrapper');
    const placeholder = wrapper ? wrapper.querySelector('.lazy-image-placeholder') : null;

    // Create new image to preload
    const tempImg = new Image();
    tempImg.onload = () => {
      // Set source
      img.src = src;
      img.removeAttribute('data-src');

      // Fade in
      img.style.transition = 'opacity 0.3s';
      img.style.opacity = '1';

      // Fade out placeholder
      if (placeholder) {
        placeholder.style.opacity = '0';
        setTimeout(() => {
          placeholder.remove();
        }, 300);
      }

      // Dispatch loaded event
      img.dispatchEvent(new CustomEvent('imageloaded', {
        detail: { img }
      }));
    };

    tempImg.onerror = () => {
      console.error('Failed to load image:', src);
      img.alt = img.alt + ' (failed to load)';
      if (placeholder) {
        placeholder.style.filter = 'none';
        placeholder.style.opacity = '0.3';
      }
    };

    tempImg.src = src;
  }

  // ===================================================================
  // DEFERRED COMPONENT RENDERING
  // ===================================================================

  /**
   * Handle deferred component entering viewport
   */
  function handleComponentIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const component = entry.target;
        if (component.dataset.rendered !== 'true') {
          renderDeferredComponent(component);
          componentObserver.unobserve(component);
        }
      }
    });
  }

  /**
   * Render a deferred component
   */
  function renderDeferredComponent(component) {
    const componentType = component.dataset.componentType;
    const componentData = component.dataset.componentData;

    if (!componentType) return;

    try {
      // Parse component data
      const data = componentData ? JSON.parse(decodeHTMLEntities(componentData)) : {};

      // Render based on type
      let html = '';
      switch (componentType) {
        case 'micronutrient-panel':
          html = renderMicronutrientPanel(data);
          break;
        case 'macro-bars':
          html = renderMacroBars(data);
          break;
        case 'calorie-card':
          html = renderCalorieCard(data);
          break;
        case 'meal-entries':
          html = renderMealEntries(data);
          break;
        case 'recipe-grid':
          html = renderRecipeGrid(data);
          break;
        default:
          console.warn('Unknown component type:', componentType);
          return;
      }

      // Fade out skeleton
      component.style.opacity = '0';
      component.style.transition = 'opacity 0.3s';

      setTimeout(() => {
        component.innerHTML = html;
        component.style.opacity = '1';
        component.dataset.rendered = 'true';

        // Dispatch custom event
        component.dispatchEvent(new CustomEvent('componentrendered', {
          detail: { component, type: componentType }
        }));
      }, 300);

    } catch (error) {
      console.error('Error rendering deferred component:', error);
      component.innerHTML = '<p class="error">Failed to render component</p>';
    }
  }

  // ===================================================================
  // COMPONENT RENDERERS
  // ===================================================================

  /**
   * Render micronutrient panel
   */
  function renderMicronutrientPanel(data) {
    // This would be populated with actual data from the server
    // For now, return a placeholder
    return '<div class="micronutrient-panel">Micronutrient data loaded</div>';
  }

  /**
   * Render macro progress bars
   */
  function renderMacroBars(data) {
    const { protein, fat, carbs, targets } = data;
    let html = '<div class="macro-bars">';

    if (protein !== undefined && targets) {
      html += renderMacroBar('Protein', protein, targets.protein, '#28a745');
    }
    if (fat !== undefined && targets) {
      html += renderMacroBar('Fat', fat, targets.fat, '#ffc107');
    }
    if (carbs !== undefined && targets) {
      html += renderMacroBar('Carbs', carbs, targets.carbs, '#17a2b8');
    }

    html += '</div>';
    return html;
  }

  /**
   * Render single macro bar
   */
  function renderMacroBar(label, current, target, color) {
    const pct = target > 0 ? (current / target * 100) : 0;
    const pctCapped = Math.min(pct, 100);

    return `
      <div class="macro-bar">
        <div class="macro-bar-header">
          <span>${label}</span>
          <span>${current.toFixed(1)}g / ${target.toFixed(1)}g</span>
        </div>
        <div class="progress-bar">
          <div class="progress-fill" style="width: ${pctCapped}%; background: ${color};"></div>
        </div>
      </div>
    `;
  }

  /**
   * Render calorie summary card
   */
  function renderCalorieCard(data) {
    const { current, target } = data;
    return `
      <div class="calorie-summary">
        <div class="calorie-current">
          <span class="big-number">${Math.round(current)}</span>
          <span> / </span>
          <span>${Math.round(target)}</span>
          <span class="unit"> cal</span>
        </div>
      </div>
    `;
  }

  /**
   * Render meal entries
   */
  function renderMealEntries(data) {
    const { entries } = data;
    if (!entries || entries.length === 0) {
      return '<p class="empty">No meals logged yet</p>';
    }

    let html = '<ul class="meal-list">';
    entries.forEach(entry => {
      html += `
        <li class="meal-entry">
          <div class="meal-info">
            <span class="meal-name">${entry.name}</span>
            <span class="meal-servings"> (${entry.servings} serving)</span>
            <span class="meal-type-badge">${entry.type}</span>
          </div>
          <div class="meal-macros">
            ${entry.protein}P / ${entry.fat}F / ${entry.carbs}C
          </div>
        </li>
      `;
    });
    html += '</ul>';
    return html;
  }

  /**
   * Render recipe grid
   */
  function renderRecipeGrid(data) {
    const { recipes } = data;
    if (!recipes || recipes.length === 0) {
      return '<p class="empty">No recipes found</p>';
    }

    let html = '<div class="recipe-grid">';
    recipes.forEach(recipe => {
      html += `
        <a href="/recipes/${recipe.id}" class="recipe-card">
          <div class="recipe-card-content">
            <h3 class="recipe-title">${recipe.name}</h3>
            <span class="recipe-category">${recipe.category}</span>
            <div class="recipe-macros">
              <span class="macro-badge">P: ${recipe.protein}g</span>
              <span class="macro-badge">F: ${recipe.fat}g</span>
              <span class="macro-badge">C: ${recipe.carbs}g</span>
            </div>
            <div class="recipe-calories">${recipe.calories} cal</div>
          </div>
        </a>
      `;
    });
    html += '</div>';
    return html;
  }

  // ===================================================================
  // VIRTUAL SCROLLING
  // ===================================================================

  /**
   * Initialize virtual scrolling for long lists
   */
  function initVirtualScrolling() {
    document.querySelectorAll('[data-virtual-scroll="true"]').forEach(container => {
      setupVirtualScroll(container);
    });
  }

  /**
   * Setup virtual scrolling for a container
   */
  function setupVirtualScroll(container) {
    const itemHeight = parseInt(container.dataset.itemHeight, 10);
    const totalItems = parseInt(container.dataset.totalItems, 10);
    const visibleCount = parseInt(container.dataset.visibleCount, 10);

    if (!itemHeight || !totalItems || !visibleCount) return;

    const contentEl = container.querySelector('.virtual-scroll-content');
    if (!contentEl) return;

    let scrollTop = 0;
    let startIndex = 0;

    /**
     * Update visible items based on scroll position
     */
    function updateVisibleItems() {
      scrollTop = container.scrollTop;
      startIndex = Math.floor(scrollTop / itemHeight);
      const endIndex = Math.min(startIndex + visibleCount + CONFIG.virtualScrollBuffer, totalItems);

      // Adjust start index for buffer
      startIndex = Math.max(0, startIndex - CONFIG.virtualScrollBuffer);

      // Position content
      contentEl.style.transform = `translateY(${startIndex * itemHeight}px)`;

      // Render visible items
      renderVisibleItems(contentEl, startIndex, endIndex);
    }

    /**
     * Render items in visible range
     */
    function renderVisibleItems(contentEl, start, end) {
      // This should be populated with actual item data
      // For now, we'll just show item indices
      let html = '';
      for (let i = start; i < end; i++) {
        html += `<div class="virtual-item" style="height: ${itemHeight}px;">Item ${i + 1}</div>`;
      }
      contentEl.innerHTML = html;
    }

    // Throttled scroll handler
    let scrollTimeout;
    container.addEventListener('scroll', () => {
      if (scrollTimeout) {
        cancelAnimationFrame(scrollTimeout);
      }
      scrollTimeout = requestAnimationFrame(updateVisibleItems);
    });

    // Initial render
    updateVisibleItems();
  }

  // ===================================================================
  // UTILITY FUNCTIONS
  // ===================================================================

  /**
   * Decode HTML entities in JSON strings
   */
  function decodeHTMLEntities(text) {
    const textarea = document.createElement('textarea');
    textarea.innerHTML = text;
    return textarea.value;
  }

  /**
   * Fallback for browsers without Intersection Observer
   */
  function loadAllEagerly() {
    // Load all lazy sections
    document.querySelectorAll('[data-lazy-load="true"]').forEach(section => {
      loadLazySection(section);
    });

    // Load all lazy images
    document.querySelectorAll('img.lazy-image').forEach(img => {
      loadLazyImage(img);
    });

    // Render all deferred components
    document.querySelectorAll('.deferred-component').forEach(component => {
      renderDeferredComponent(component);
    });
  }

  /**
   * Cleanup observers on page unload
   */
  function cleanup() {
    if (lazyObserver) lazyObserver.disconnect();
    if (imageObserver) imageObserver.disconnect();
    if (componentObserver) componentObserver.disconnect();
  }

  // ===================================================================
  // INITIALIZATION
  // ===================================================================

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLazyLoading);
  } else {
    initLazyLoading();
  }

  // Cleanup on unload
  window.addEventListener('beforeunload', cleanup);

  // Export for testing
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      initLazyLoading,
      loadLazySection,
      loadLazyImage,
      renderDeferredComponent
    };
  }

})();
