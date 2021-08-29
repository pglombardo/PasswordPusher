import generatePassword from "omgopass";

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

    setupPwGeneratorEvents() {
        // Generate Password button
        $('#generate_password').on('click', () => {
            $('#password_payload').val(generatePassword(this.config)).trigger('input');
        });
        
        // Configure Generator: Generate Password button
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
        });
        
        $('#save_configure').on('click', () => {
            // Save options to cookie and close
        });
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

        this.updateForm(true);
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