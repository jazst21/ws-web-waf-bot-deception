// ===== MAIN JAVASCRIPT FUNCTIONALITY =====

document.addEventListener('DOMContentLoaded', function() {
    // Initialize all functionality
    initLanguageToggle();
    initNavigationHighlighting();
    initSmoothAnimations();
    initFormEnhancements();
    initCommentInteractions();
});

// ===== LANGUAGE TOGGLE FUNCTIONALITY =====
function initLanguageToggle() {
    const langToggle = document.getElementById('langToggle');
    if (!langToggle) return;

    let currentLang = 'EN';
    const languages = {
        'EN': '🌐 EN',
        'KO': '🌐 KO',
        'JA': '🌐 JA',
        'ZH': '🌐 ZH'
    };

    langToggle.addEventListener('click', function() {
        // Cycle through languages
        const langKeys = Object.keys(languages);
        const currentIndex = langKeys.indexOf(currentLang);
        const nextIndex = (currentIndex + 1) % langKeys.length;
        currentLang = langKeys[nextIndex];
        
        langToggle.textContent = languages[currentLang];
        
        // Add visual feedback
        langToggle.style.transform = 'scale(0.95)';
        setTimeout(() => {
            langToggle.style.transform = 'scale(1)';
        }, 150);
        
        // Here you could implement actual language switching
        console.log(`Language switched to: ${currentLang}`);
    });
}

// ===== NAVIGATION HIGHLIGHTING =====
function initNavigationHighlighting() {
    const navLinks = document.querySelectorAll('.nav-link');
    const currentPath = window.location.pathname;
    
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.classList.add('active');
        }
        
        // Add hover effects
        link.addEventListener('mouseenter', function() {
            this.style.transform = 'translateX(8px)';
        });
        
        link.addEventListener('mouseleave', function() {
            this.style.transform = 'translateX(0)';
        });
    });
}

// ===== SMOOTH ANIMATIONS =====
function initSmoothAnimations() {
    // Add fade-in animation to content sections
    const contentSections = document.querySelectorAll('.content-section, .welcome-card, .demo-card, .comment-item');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });
    
    contentSections.forEach(section => {
        observer.observe(section);
    });
}

// ===== FORM ENHANCEMENTS =====
function initFormEnhancements() {
    const forms = document.querySelectorAll('form');
    
    forms.forEach(form => {
        const inputs = form.querySelectorAll('input, textarea');
        
        inputs.forEach(input => {
            // Add floating label effect
            input.addEventListener('focus', function() {
                this.parentElement.classList.add('focused');
            });
            
            input.addEventListener('blur', function() {
                if (!this.value) {
                    this.parentElement.classList.remove('focused');
                }
            });
            
            // Add character counter for textareas
            if (input.tagName === 'TEXTAREA') {
                const counter = document.createElement('div');
                counter.className = 'char-counter';
                counter.style.cssText = 'font-size: 0.75rem; color: var(--text-muted); text-align: right; margin-top: 0.25rem;';
                input.parentElement.appendChild(counter);
                
                input.addEventListener('input', function() {
                    const remaining = 1000 - this.value.length;
                    counter.textContent = `${this.value.length}/1000 characters`;
                    counter.style.color = remaining < 100 ? 'var(--warning-color)' : 'var(--text-muted)';
                });
            }
        });
        
        // Add form submission feedback
        form.addEventListener('submit', function(e) {
            const submitBtn = this.querySelector('button[type="submit"]');
            if (submitBtn) {
                const originalText = submitBtn.textContent;
                submitBtn.textContent = 'Saving...';
                submitBtn.disabled = true;
                
                // Re-enable after a short delay (simulating server response)
                setTimeout(() => {
                    submitBtn.textContent = originalText;
                    submitBtn.disabled = false;
                }, 2000);
            }
        });
    });
}

// ===== COMMENT INTERACTIONS =====
function initCommentInteractions() {
    const commentItems = document.querySelectorAll('.comment-item');
    
    commentItems.forEach(comment => {
        // Add click to expand functionality for long comments
        const content = comment.querySelector('.comment-content');
        if (content && content.textContent.length > 200) {
            content.style.maxHeight = '4.8em';
            content.style.overflow = 'hidden';
            content.style.cursor = 'pointer';
            
            content.addEventListener('click', function() {
                if (this.style.maxHeight === '4.8em') {
                    this.style.maxHeight = 'none';
                    this.style.cursor = 'default';
                } else {
                    this.style.maxHeight = '4.8em';
                    this.style.cursor = 'pointer';
                }
            });
            
            // Add visual indicator
            const expandIndicator = document.createElement('div');
            expandIndicator.textContent = 'Click to expand';
            expandIndicator.style.cssText = 'font-size: 0.75rem; color: var(--primary-color); cursor: pointer; margin-top: 0.5rem;';
            content.parentElement.appendChild(expandIndicator);
            
            expandIndicator.addEventListener('click', function() {
                if (content.style.maxHeight === '4.8em') {
                    content.style.maxHeight = 'none';
                    content.style.cursor = 'default';
                    this.textContent = 'Click to collapse';
                } else {
                    content.style.maxHeight = '4.8em';
                    content.style.cursor = 'pointer';
                    this.textContent = 'Click to expand';
                }
            });
        }
        
        // Add hover effects for bot comments
        if (comment.classList.contains('bot-comment')) {
            comment.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-4px) scale(1.02)';
                this.style.boxShadow = 'var(--shadow-xl)';
            });
            
            comment.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0) scale(1)';
                this.style.boxShadow = 'var(--shadow-md)';
            });
        }
    });
}

// ===== UTILITY FUNCTIONS =====

// Debounce function for performance
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Smooth scroll to element
function smoothScrollTo(element) {
    element.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
    });
}

// Add loading state to buttons
function addLoadingState(button, text = 'Loading...') {
    const originalText = button.textContent;
    button.textContent = text;
    button.disabled = true;
    button.style.opacity = '0.7';
    
    return function() {
        button.textContent = originalText;
        button.disabled = false;
        button.style.opacity = '1';
    };
}

// Show notification
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 1rem 1.5rem;
        border-radius: var(--radius-md);
        color: white;
        font-weight: 600;
        z-index: 10000;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        max-width: 300px;
    `;
    
    // Set background color based on type
    const colors = {
        success: 'var(--success-color)',
        error: 'var(--danger-color)',
        warning: 'var(--warning-color)',
        info: 'var(--primary-color)'
    };
    notification.style.backgroundColor = colors[type] || colors.info;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// ===== KEYBOARD SHORTCUTS =====
document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + K to focus search (if implemented)
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        // Focus search input if it exists
        const searchInput = document.querySelector('input[type="search"]');
        if (searchInput) {
            searchInput.focus();
        }
    }
    
    // Escape to close modals or clear focus
    if (e.key === 'Escape') {
        const activeElement = document.activeElement;
        if (activeElement && (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA')) {
            activeElement.blur();
        }
    }
});

// ===== PERFORMANCE OPTIMIZATIONS =====

// Lazy load images
function initLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');
    
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                imageObserver.unobserve(img);
            }
        });
    });
    
    images.forEach(img => imageObserver.observe(img));
}

// Throttle scroll events
const throttledScroll = debounce(() => {
    // Handle scroll-based animations or effects
    const scrolled = window.pageYOffset;
    const parallaxElements = document.querySelectorAll('.parallax');
    
    parallaxElements.forEach(element => {
        const speed = element.dataset.speed || 0.5;
        element.style.transform = `translateY(${scrolled * speed}px)`;
    });
}, 16);

window.addEventListener('scroll', throttledScroll);

// ===== ACCESSIBILITY ENHANCEMENTS =====

// Add skip to content link
function addSkipToContent() {
    const skipLink = document.createElement('a');
    skipLink.href = '#main-content';
    skipLink.textContent = 'Skip to main content';
    skipLink.style.cssText = `
        position: absolute;
        top: -40px;
        left: 6px;
        background: var(--primary-color);
        color: white;
        padding: 8px;
        text-decoration: none;
        border-radius: var(--radius-sm);
        z-index: 10001;
        transition: top 0.3s;
    `;
    
    skipLink.addEventListener('focus', function() {
        this.style.top = '6px';
    });
    
    skipLink.addEventListener('blur', function() {
        this.style.top = '-40px';
    });
    
    document.body.insertBefore(skipLink, document.body.firstChild);
}

// Initialize accessibility features
addSkipToContent();

// ===== ERROR HANDLING =====
window.addEventListener('error', function(e) {
    console.error('JavaScript error:', e.error);
    showNotification('An error occurred. Please refresh the page.', 'error');
});

// ===== EXPORT FOR GLOBAL USE =====
window.BotTrapperUI = {
    showNotification,
    smoothScrollTo,
    addLoadingState,
    debounce
}; 