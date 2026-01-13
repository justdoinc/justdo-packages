// https://raw.githubusercontent.com/polonel/SnackBar/036f63cca0ac55170b8c1483a9142e39e289aa7f/dist/snackbar.js

// JUSTDOers! IMPORTANT! I (Daniel) Added XSS protections below, if you upgrade to
// heigher version - pay attention to keep them!

// Note, I decided to do it here, and not in our layer, to avoid letting any plugin
// developer accidentally using it directly without XSS protection.

// Also, in case of upgrade that will add additional fields that need guarding - 
// my hope is that whoever will do the upgrade will notice the need to add guarding
// to these fields.

/*!
 * Snackbar v0.1.11
 * http://polonel.com/Snackbar
 *
 * Copyright 2018 Chris Brame and other contributors
 * Released under the MIT license
 * https://github.com/polonel/Snackbar/blob/master/LICENSE
 */

(function(root, factory) {
    'use strict';

    if (typeof define === 'function' && define.amd) {
        define([], function() {
            return (root.Snackbar = factory());
        });
    } else if (typeof module === 'object' && module.exports) {
        module.exports = root.Snackbar = factory();
    } else {
        root.Snackbar = factory();
    }
})(this, function() {
    const $snackbarContainer = document.createElement('div');
    $snackbarContainer.className = 'justdo-snackbar-container';
    document.body.appendChild($snackbarContainer);

    var Snackbar = {};

    Snackbar.current = [];
    Snackbar.isPaused = false;
    
    var $defaults = {
        text: 'Default Text',
        textColor: '#FFFFFF',
        width: 'fit-content',
        showAction: true,
        showDismissButton: false,
        actionText: '<svg class="jd-icon" style="stroke-width: 2;"><use xlink:href="/layout/icons-feather-sprite.svg#x"/></svg>',
        actionTextColor: '#4CAF50',
        showSecondButton: false,
        secondButtonText: '',
        secondButtonTextColor: '#4CAF50',
        backgroundColor: '#323232',
        pos: 'bottom-left',
        // To show the snackbar indefinitely, set duration to 0
        duration: 5000,
        customClass: '',
        onActionClick: function(element) {
            element.style.opacity = 0;
        },
        onSecondButtonClick: function(element) {},
        onClose: function(element) {}
    };

    Snackbar.show = function($options) {
        // For cases where the user didn't explicitly set an action or second action - set the framework minimum duration to 10 seconds.
        // Otherwise, set the minimum framework duration is set to 30 seconds.
        var minimum_duration = 10 * 1000; // 10 seconds
        if ($options.onSecondButtonClick || $options.onActionClick) {
            minimum_duration = 30 * 1000; // 30 seconds
        }

        var options = Extend(true, $defaults, $options);
        if (options.duration <= 0) {
            // Normalize negative duration
            options.duration = 0;
        }

        if (options.duration > 0) {
            // Enforce minimum duration only if duration is greater than 0 (0 should show indefinetly).
            options.duration = Math.max(options.duration, minimum_duration);
        }

        // for option_name, option_val of options
        //   if _.isString(option_val)
        //     if option_name in ["text", "actionText", "secondButtonText"]
        //       options[option_name] = JustdoHelpers.xssGuard(option_val, {allow_html_parsing: true, enclosing_char: ""})
        //     else
        //       options[option_name] = JustdoHelpers.xssGuard(option_val)

        var option_name, option_val;

        for (option_name in options) {
          option_val = options[option_name];
          if (_.isString(option_val)) {
            if (option_name === "text" || option_name === "actionText" || option_name === "secondButtonText") {
              options[option_name] = JustdoHelpers.xssGuard(option_val, {
                allow_html_parsing: true,
                enclosing_char: "",
                noFormatting: true
              });
            } else {
              options[option_name] = JustdoHelpers.xssGuard(option_val, {
                noFormatting: true
              });
            }
          }
        }

        var snackbar = document.createElement('div');
        snackbar.className = 'snackbar-container ' + options.customClass;
        snackbar.style.width = options.width;
        var $p = document.createElement('p');
        $p.style.margin = 0;
        $p.style.padding = 0;
        $p.style.color = options.textColor;
        $p.style.fontSize = '14px';
        $p.style.fontWeight = 400;
        $p.style.lineHeight = '1em';
        $p.innerHTML = options.text;
        snackbar.appendChild($p);
        snackbar.style.background = options.backgroundColor;
        var $buttonWrapper = document.createElement('div');
        $buttonWrapper.className = "snackbar-button-wrapper";
        snackbar.appendChild($buttonWrapper); // Wrapper for buttons

        // Add progress bar
        var $progressBar = document.createElement('div');
        $progressBar.className = 'snackbar-progress-bar bg-warning';
        snackbar.appendChild($progressBar);

        // Add timer state tracking
        snackbar._duration = options.duration;
        snackbar._remainingTime = options.duration;
        snackbar._timeoutId = null;
        snackbar._progressStartTime = Date.now();

        snackbar.close = function() {
            if (this._timeoutId) {
                clearTimeout(this._timeoutId);
            }
            this.style.opacity = 0;
            this.style.top = '-100px';
            this.style.bottom = '-100px';
        }.bind(snackbar);

        if (options.showSecondButton) {
            var secondButton = document.createElement('button');
            secondButton.className = 'action';
            secondButton.innerHTML = options.secondButtonText;
            secondButton.style.color = options.secondButtonTextColor;
            secondButton.addEventListener('click', function() {
                options.onSecondButtonClick(snackbar);
            });
            $buttonWrapper.appendChild(secondButton);
        }

        if (options.showAction) {
            var actionButton = document.createElement('button');
            actionButton.className = 'action';
            actionButton.innerHTML = options.actionText;
            actionButton.style.color = options.actionTextColor;
            actionButton.addEventListener('click', function() {
                options.onActionClick(snackbar);
            });
            $buttonWrapper.appendChild(actionButton);
        }

        if (options.showDismissButton) {
            var dismissButton = document.createElement('button');
            dismissButton.className = 'action';
            dismissButton.innerHTML = '<svg class="jd-icon" style="stroke-width: 2;"><use xlink:href="/layout/icons-feather-sprite.svg#x"/></svg>';
            dismissButton.style.color = options.secondButtonTextColor;
            dismissButton.addEventListener('click', function() {
                snackbar.close();
            });
            $buttonWrapper.appendChild(dismissButton);
        }

        // Helper to animate progress bar from initial width to 0%
        var animateProgressBar = function(progressBar, initialWidth, duration, delay) {
            progressBar.style.transition = 'none';
            progressBar.style.width = initialWidth;
            progressBar.offsetHeight; // Force reflow
            
            var animate = function() {
                progressBar.style.transition = 'width ' + duration + 'ms linear';
                progressBar.style.width = '0%';
            };
            
            delay ? setTimeout(animate, delay) : animate();
        };

        // Function to start/restart the timer
        snackbar.startTimer = function(isInitialStart) {
            if (this._timeoutId) {
                clearTimeout(this._timeoutId);
            }
            
            // If time expired while paused, close immediately
            if (this._remainingTime === 0) {
                this.close();
                return;
            }
            
            this._progressStartTime = Date.now();
            
            var progressBar = this.querySelector('.snackbar-progress-bar');
            if (progressBar) {
                var initialWidth = isInitialStart 
                    ? '100%' 
                    : ((this._remainingTime / this._duration) * 100) + '%';
                var delay = isInitialStart ? 10 : 0;
                animateProgressBar(progressBar, initialWidth, this._remainingTime, delay);
            }
            
            this._timeoutId = setTimeout(this.close.bind(this), this._remainingTime);
        }.bind(snackbar);

        // Function to pause the timer
        snackbar.pauseTimer = function() {
            if (this._timeoutId) {
                clearTimeout(this._timeoutId);
                this._timeoutId = null;
            }
            
            var elapsed = Date.now() - this._progressStartTime;
            this._remainingTime = Math.max(0, this._remainingTime - elapsed);
            
            var progressBar = this.querySelector('.snackbar-progress-bar');
            if (progressBar) {
                var currentWidth = progressBar.offsetWidth;
                var parentWidth = progressBar.parentElement.offsetWidth;
                var percentageWidth = (currentWidth / parentWidth) * 100;
                progressBar.style.transition = 'none';
                progressBar.style.width = percentageWidth + '%';
            }
        }.bind(snackbar);

        // Helper to toggle pause state for all snackbars
        var togglePauseState = function(shouldPause) {
            if (Snackbar.isPaused === shouldPause) return;
            
            Snackbar.isPaused = shouldPause;
            Snackbar.current.forEach(function(sb) {
                if (shouldPause) {
                    sb.pauseTimer();
                } else {
                    sb.startTimer(false);
                }
            });
        };

        // Hover event handlers
        snackbar.addEventListener('mouseenter', function() {
            togglePauseState(true);
        });

        snackbar.addEventListener('mouseleave', function() {
            togglePauseState(false);
        });

        if (options.duration) {
            snackbar.startTimer(true); // Initial start from 100%
        }

        snackbar.addEventListener(
            'transitionend',
            function(event, elapsed) {
                if (event.propertyName === 'opacity' && this.style.opacity === '0') {
                    if (typeof(options.onClose) === 'function')
                        options.onClose(this);

                    this.parentElement.removeChild(this);
                    Snackbar.current = _.without(Snackbar.current, this);
                }
            }.bind(snackbar)
        );

        Snackbar.current.push(snackbar);

        $snackbarContainer.appendChild(snackbar);
        var $bottom = getComputedStyle(snackbar).bottom;
        var $top = getComputedStyle(snackbar).top;
        snackbar.style.opacity = 1;
        snackbar.className =
            'snackbar-container ' + options.customClass + ' snackbar-pos ' + options.pos;
        
        return snackbar;
    };

    // Pure JS Extend
    // http://gomakethings.com/vanilla-javascript-version-of-jquery-extend/
    var Extend = function() {
        var extended = {};
        var deep = false;
        var i = 0;
        var length = arguments.length;

        if (Object.prototype.toString.call(arguments[0]) === '[object Boolean]') {
            deep = arguments[0];
            i++;
        }

        var merge = function(obj) {
            for (var prop in obj) {
                if (Object.prototype.hasOwnProperty.call(obj, prop)) {
                    if (deep && Object.prototype.toString.call(obj[prop]) === '[object Object]') {
                        extended[prop] = Extend(true, extended[prop], obj[prop]);
                    } else {
                        extended[prop] = obj[prop];
                    }
                }
            }
        };

        for (; i < length; i++) {
            var obj = arguments[i];
            merge(obj);
        }

        return extended;
    };

    return Snackbar;
});