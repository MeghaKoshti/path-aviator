document.addEventListener('DOMContentLoaded', function() {
  // Only run on sign-in page
  if (!document.querySelector('.signin-page')) return;

  initializePasswordToggle();
  initializeFormInteractions();
  initializeNeuralNetworkAnimation();
  autoFocusEmailField();
});

function initializePasswordToggle() {
  const passwordField = document.getElementById('password-field');
  const passwordToggle = document.getElementById('password-toggle');
  const eyeIcon = document.getElementById('eye-icon');

  if (!passwordToggle || !passwordField || !eyeIcon) return;

  passwordToggle.addEventListener('click', function(e) {
    e.preventDefault();
    const isPassword = passwordField.type === 'password';
    passwordField.type = isPassword ? 'text' : 'password';
    
    // Update eye icon - Fixed for better browser compatibility
    const eyeOpenPath = 'M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z';
    const eyeClosedPath = 'M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L8.464 8.464M9.878 9.878L8 12m6.121-2.122L16.536 8.464M14.12 14.12L16 12m-2.12 2.12l1.415 1.415M14.12 14.12L12 16m2.121-1.879l2.122 2.122';
    
    const pathToUse = isPassword ? eyeClosedPath : eyeOpenPath;
    
    // Clear existing paths and add new one
    eyeIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="' + pathToUse + '" />';
    
    // Add ARIA attributes for accessibility
    passwordToggle.setAttribute('aria-label', isPassword ? 'Hide password' : 'Show password');
  });
}

function initializeFormInteractions() {
  // Enhanced form field interactions with better error handling
  const formFields = document.querySelectorAll('.signin-page input');
  
  formFields.forEach(function(input) {
    input.addEventListener('focus', function() {
      if (this.style) {
        this.style.transform = 'scale(1.02)';
      }
    });
    
    input.addEventListener('blur', function() {
      if (this.style) {
        this.style.transform = 'scale(1)';
      }
    });
  });

  // Form submission handling
  const form = document.getElementById('signin-form');
  if (form) {
    form.addEventListener('submit', function(e) {
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]');
      if (submitButton) {
        // Store original text
        const originalText = submitButton.textContent || submitButton.value;
        
        submitButton.style.opacity = '0.8';
        submitButton.disabled = true;
        
        // Update button text based on element type
        if (submitButton.tagName === 'INPUT') {
          submitButton.value = 'Signing In...';
        } else {
          submitButton.textContent = 'Signing In...';
        }
        
        // Re-enable after 3 seconds to prevent permanent disable on validation errors
        setTimeout(function() {
          submitButton.style.opacity = '1';
          submitButton.disabled = false;
          
          // Restore original text
          if (submitButton.tagName === 'INPUT') {
            submitButton.value = originalText;
          } else {
            submitButton.textContent = originalText;
          }
        }, 3000);
      }
    });
  }
}

function initializeNeuralNetworkAnimation() {
  const network = document.querySelector('.neural-network');
  if (!network) return;

  let animationId;
  
  function animateNetwork() {
    const time = Date.now() * 0.001;
    
    // Build background position string with better browser compatibility
    const pos1 = Math.sin(time) * 50 + 'px ' + Math.cos(time) * 50 + 'px';
    const pos2 = Math.cos(time * 1.5) * 30 + 'px ' + Math.sin(time * 1.5) * 30 + 'px';
    const pos3 = Math.sin(time * 2) * 40 + 'px ' + Math.cos(time * 2) * 40 + 'px';
    
    network.style.backgroundPosition = pos1 + ', ' + pos2 + ', ' + pos3;
    animationId = requestAnimationFrame(animateNetwork);
  }
  
  // Check for reduced motion preference
  if (!window.matchMedia || !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    animateNetwork();
  }

  // Cleanup on page unload
  window.addEventListener('beforeunload', function() {
    if (animationId) {
      cancelAnimationFrame(animationId);
    }
  });
}

function autoFocusEmailField() {
  const emailField = document.querySelector('.signin-page input[type="email"]');
  if (emailField && !emailField.value) {
    // Small delay to ensure page is fully loaded
    setTimeout(function() {
      emailField.focus();
    }, 100);
  }
}

// Enhanced keyboard navigation with better Rails form compatibility
document.addEventListener('keydown', function(e) {
  if (!document.querySelector('.signin-page')) return;
  
  if (e.key === 'Enter' && e.target.tagName === 'INPUT') {
    const form = e.target.closest('form');
    if (form) {
      const inputs = Array.from(form.querySelectorAll('input[type="email"], input[type="password"]'));
      const currentIndex = inputs.indexOf(e.target);
      
      if (currentIndex < inputs.length - 1) {
        // Focus next input
        e.preventDefault();
        inputs[currentIndex + 1].focus();
      } else {
        // Submit form if on last input - let Rails handle it naturally
        const submitButton = form.querySelector('input[type="submit"], button[type="submit"]');
        if (submitButton) {
          submitButton.click();
        }
      }
    }
  }
});

// Social signin handlers with Rails compatibility
function handleSocialSignin(provider) {
  console.log('Initiating ' + provider + ' signin...');
  
  // Show loading state
  const link = event.target.closest('a');
  if (link) {
    const originalText = link.innerHTML;
    link.innerHTML = '<span>Loading...</span>';
    
    // Restore after delay if something goes wrong
    setTimeout(function() {
      link.innerHTML = originalText;
    }, 5000);
  }
  
  // Allow the link to proceed to Rails route
  return true;
}

// Form validation helpers for Rails
function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function showFieldError(field, message) {
  // Remove existing error
  const existingError = field.parentNode.querySelector('.field-error');
  if (existingError) {
    existingError.remove();
  }
  
  // Add new error message
  const errorDiv = document.createElement('div');
  errorDiv.className = 'field-error text-red-500 text-sm mt-1';
  errorDiv.textContent = message;
  field.parentNode.appendChild(errorDiv);
  
  // Add error styling to field
  field.classList.add('border-red-500');
  field.classList.remove('border-gray-200');
}

function clearFieldError(field) {
  const existingError = field.parentNode.querySelector('.field-error');
  if (existingError) {
    existingError.remove();
  }
  
  // Remove error styling
  field.classList.remove('border-red-500');
  field.classList.add('border-gray-200');
}

// Client-side validation (optional - Rails will handle server-side)
function validateForm() {
  const emailField = document.getElementById('email');
  const passwordField = document.getElementById('password-field');
  let isValid = true;
  
  // Clear previous errors
  clearFieldError(emailField);
  clearFieldError(passwordField);
  
  // Validate email
  if (!emailField.value) {
    showFieldError(emailField, 'Email is required');
    isValid = false;
  } else if (!validateEmail(emailField.value)) {
    showFieldError(emailField, 'Please enter a valid email address');
    isValid = false;
  }
  
  // Validate password
  if (!passwordField.value) {
    showFieldError(passwordField, 'Password is required');
    isValid = false;
  } else if (passwordField.value.length < 6) {
    showFieldError(passwordField, 'Password must be at least 6 characters');
    isValid = false;
  }
  
  return isValid;
}

// Add form validation on submit (optional)
document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('signin-form');
  if (form) {
    form.addEventListener('submit', function(e) {
      // Only validate if you want client-side validation
      // Comment out these lines if you prefer Rails-only validation
      /*
      if (!validateForm()) {
        e.preventDefault();
        return false;
      }
      */
    });
  }
});