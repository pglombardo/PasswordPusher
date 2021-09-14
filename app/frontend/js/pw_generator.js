import Cookies from 'js-cookie'
import generatePassword from "omgopass";
import toBoolean from '../js/toolbox'

class PasswordGenerator {
    constructor() {
        this.config = {
            hasNumbers: true,
            titlecased: true,
            use_separators: true,
            consonants: 'bcdfghklmnprstvz',
            vowels: 'aeiouy',
            separators: '-_=',
            maxSyllableLength: 3,
            minSyllableLength: 1,
            syllablesCount: 3
        }

        this.config_defaults = {
            hasNumbers: true,
            titlecased: true,
            use_separators: true,
            consonants: 'bcdfghklmnprstvz',
            vowels: 'aeiouy',
            separators: '-_=',
            maxSyllableLength: 3,
            minSyllableLength: 1,
            syllablesCount: 3,
        };
    }

    onReady() {
        this.loadValuesFromCookie();
        this.setupPwGeneratorEvents();
        this.updateForm();
    }

    setupPwGeneratorEvents() {
        var ga_enabled = false;

        if ($('meta[name=ga_enabled]').attr('content') == "true") {
            ga_enabled = true;
        }

        // Generate Password button
        $('#generate_password').on('click', () => {
            $('#password_payload').val(generatePassword(this.config)).trigger('input');
            if (ga_enabled) {
                gtag('event', 'generate_password',
                     { 'event_category' : 'engagement',
                       'event_label' : 'Generate a Password' });
            }
        });

        if (ga_enabled) {
            // Configure Generator Button
            $('#configure_generator').on('click', () => {
                gtag('event', 'configure_pw_generator',
                     { 'event_category' : 'engagement',
                       'event_label' : 'Configure Password Generator Dialog' });
            });

            // Create Account Button
            $('#create_account_button').on('click', () => {
                gtag('event', 'create_account',
                     { 'event_category' : 'engagement',
                       'event_label' : 'New Account Creation' });
            });
        }

        // Configure Generator Dialog: Generate Password button
        $('#configure_generate_password').on('click', () => {
            $('#configure_password_payload').text(generatePassword(this.config));
        });

        // hasNumbers
        $('#include_numbers').on('change', () => {
            this.config.hasNumbers = $('#include_numbers').prop('checked');
        });

        // titlecased
        $('#use_titlecase').on('change', () => {
            this.config.titlecased = $('#use_titlecase').prop('checked');
        });

        // separators
        $('#use_separators').on('change', () => {
            let is_checked = $('#use_separators').prop('checked');
            this.config.use_separators = is_checked;

            if (is_checked) {
                this.config.separators = this.config_defaults.separators;
                $('#separators').val(this.config.separators);
            } else {
                this.config.separators = '';
                $('#separators').val('');
            }
        });

        // separators
        $('#separators').on('change input', () => {
            this.config.separators = $('#separators').val()
        });


        // num_syllables
        $('#num_syllables').on('change input', () => {
            var num_syllables_as_int = parseInt($('#num_syllables').val());
            if (typeof num_syllables_as_int === 'number') {
                this.config.syllablesCount = num_syllables_as_int;
            }
        });

        // min_syllable_length
        $('#min_syllable_length').on('change input', () => {
            var min_syllable_length_as_int = parseInt($('#min_syllable_length').val());
            if (typeof min_syllable_length_as_int === 'number') {
                this.config.minSyllableLength = min_syllable_length_as_int;
            }
        });

        // max_syllable_length
        $('#max_syllable_length').on('change input', () => {
            var max_syllable_length_as_int = parseInt($('#max_syllable_length').val());
            if (typeof max_syllable_length_as_int === 'number') {
                this.config.maxSyllableLength = max_syllable_length_as_int;
            }
        });

        // vowels
        $('#vowels').on('change input', () => {
            this.config.vowels = $('#vowels').val()
        });

        // consonants
        $('#consonants').on('change input', () => {
           this.config.consonants = $('#consonants').val()
        });

        // Reset to defaults
        $('#reset_to_defaults').on('click', () => {
            this.resetToDefaults();
            this.updateForm();
        });

        $('#save_configure').on('click', () => {
            // Save options to cookie and close
            this.saveValuesToCookie();
        });
    }

    saveValuesToCookie() {
        Cookies.set('hasNumbers',        this.config.hasNumbers.toString(), { expires: 365 });
        Cookies.set('titlecased',        this.config.titlecased.toString(), { expires: 365 });
        Cookies.set('use_separators',    this.config.use_separators.toString(), { expires: 365 });
        Cookies.set('consonants',        this.config.consonants, { expires: 365 });
        Cookies.set('vowels',            this.config.vowels, { expires: 365 });
        Cookies.set('separators',        this.config.separators, { expires: 365 });
        Cookies.set('maxSyllableLength', this.config.maxSyllableLength, { expires: 365 });
        Cookies.set('minSyllableLength', this.config.minSyllableLength, { expires: 365 });
        Cookies.set('syllablesCount',    this.config.syllablesCount, { expires: 365 });
    }

    loadValuesFromCookie() {
        // Booleans
        let has_numbers = Cookies.get('hasNumbers');
        if (has_numbers) {
            this.config.hasNumbers = toBoolean(has_numbers);
        } else {
            this.config.hasNumbers = this.config_defaults.hasNumbers;
        }

        let titlecased = Cookies.get('titlecased');
        if (titlecased) {
            this.config.titlecased = toBoolean(titlecased);
        } else {
            this.config.titlecased = this.config_defaults.titlecased;
        }

        let use_separators = Cookies.get('use_separators');
        if (use_separators) {
            this.config.use_separators = toBoolean(use_separators);
        } else {
            this.config.use_separators = this.config_defaults.use_separators;
        }

        // Strings
        this.config.consonants = Cookies.get('consonants') || this.config_defaults.consonants;
        this.config.vowels = Cookies.get('vowels') || this.config_defaults.vowels;
        this.config.separators = Cookies.get('separators') || this.config_defaults.separators;

        // Integers
        this.config.maxSyllableLength = parseInt(Cookies.get('maxSyllableLength'), 10) || this.config_defaults.maxSyllableLength;
        this.config.minSyllableLength = parseInt(Cookies.get('minSyllableLength'), 10) || this.config_defaults.minSyllableLength;
        this.config.syllablesCount = parseInt(Cookies.get('syllablesCount'), 10) || this.config_defaults.syllablesCount;
    }

    resetToDefaults() {
        this.config.hasNumbers = this.config_defaults.hasNumbers;
        this.config.titlecased = this.config_defaults.titlecased;
        this.config.use_separators = this.config_defaults.use_separators;
        this.config.consonants = this.config_defaults.consonants;
        this.config.vowels = this.config_defaults.vowels;
        this.config.separators = this.config_defaults.separators;
        this.config.maxSyllableLength = this.config_defaults.maxSyllableLength;
        this.config.minSyllableLength = this.config_defaults.minSyllableLength;
        this.config.syllablesCount = this.config_defaults.syllablesCount;
    }

    updateForm(with_defaults = false) {

        let candidate = this.config;
        if (with_defaults) {
            candidate = this.config_defaults;
        }

        $('#separators').val(candidate.separators)
        $('#consonants').val(candidate.consonants)
        $('#vowels').val(candidate.vowels)
        $('#max_syllable_length').val(candidate.maxSyllableLength)
        $('#min_syllable_length').val(candidate.minSyllableLength)
        $('#num_syllables').val(candidate.syllablesCount)
        $('#use_separators').prop('checked', candidate.use_separators);
        $('#use_titlecase').prop('checked', candidate.titlecased);
        $('#include_numbers').prop('checked', candidate.hasNumbers);
    }
}




export default (new PasswordGenerator);