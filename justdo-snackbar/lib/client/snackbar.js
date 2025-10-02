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
        duration: 5000,
        customClass: '',
        onActionClick: function(element) {
            element.style.opacity = 0;
        },
        onSecondButtonClick: function(element) {},
        onClose: function(element) {}
    };

    Snackbar.show = function($options) {
        var options = Extend(true, $defaults, $options);

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
                enclosing_char: ""
              });
            } else {
              options[option_name] = JustdoHelpers.xssGuard(option_val);
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

        snackbar.close = function() {
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

        if (options.duration) {
            setTimeout(
                function() {
                    snackbar.close();
                }.bind(snackbar),
                options.duration
            );
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