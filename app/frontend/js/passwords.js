import 'spoiler-alert/spoiler'

import ClipboardJS from 'clipboard'
import generatePassword from "omgopass";

function setCookie(name,value,days) {
  var expires = "";
  if (days) {
      var date = new Date();
      date.setTime(date.getTime() + (days*24*60*60*1000));
      expires = "; expires=" + date.toUTCString();
  }
  document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}

function getCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');

  for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function restoreFormValuesFromCookie() {
  var days = getCookie('pwpush_days');
  var views = getCookie('pwpush_views');

  var de = document.getElementById("password_expire_after_days")
  var dr = document.getElementById("daysrange")
  if (de) {
    if (days) {
      de.value = days
      dr.innerText = days + " Days"
    } else {
      showDaysValue(de.value)
    }
  }

  var ve = document.getElementById("password_expire_after_views")
  var vr = document.getElementById("viewsrange")
  if (ve) {
    if (views) {
      ve.value = views
      vr.innerText = views + " Views"
    } else {
      showViewsValue(ve.value)
    }
  }

  var dbv_checkbox = document.getElementById('password_deletable_by_viewer')
  var dbv_check_state = getCookie('pwpush_dbv')
  if (dbv_checkbox) {
    var new_value = true;
    if (dbv_check_state) {
      if (dbv_check_state == "false") {
        new_value = false
      }
      if (dbv_checkbox.checked != new_value) {
        dbv_checkbox.click()
      }
    }
  }

  var retrieval_checkbox = document.getElementById('password_retrieval_step')
  var retrieval_check_state = getCookie('pwpush_retrieval')
  if (retrieval_checkbox) {
    var new_value = true;
    if (retrieval_check_state) {
      if (retrieval_check_state == "false") {
        new_value = false
      }
      if (retrieval_checkbox.checked != new_value) {
        retrieval_checkbox.click()
      }
    }
  }

}

function saveFormValuesToCookie() {
  var days_value  = document.getElementById("password_expire_after_days").value
  var views_value = document.getElementById("password_expire_after_views").value
  var dbv         = document.getElementById("password_deletable_by_viewer")
  var retrieval   = document.getElementById("password_retrieval_step")

  setCookie('pwpush_days',  days_value, 365);
  setCookie('pwpush_views', views_value, 365);
  setCookie('pwpush_dbv', dbv.checked.toString(), 365);
  setCookie('pwpush_retrieval', retrieval.checked.toString(), 365);

  let e = document.getElementById("cookie-save")
  e.innerHTML = "Saved!  <em>Defaults updated.</em>"
  return true;
}

function setupSliderEventListeners()
{
  var slider_days = document.getElementById('password_expire_after_days');
  var slider_views = document.getElementById('password_expire_after_views');

  if (slider_days) {
    slider_days.addEventListener("change", function() {
      document.getElementById("daysrange").innerText=slider_days.value + ' Days';
    })
    slider_days.addEventListener("input", function() {
      document.getElementById("daysrange").innerText=slider_days.value + ' Days';
    })
  }

  if (slider_views) {
    slider_views.addEventListener("change", function() {
      document.getElementById("viewsrange").innerText=slider_views.value + ' Days';
    })
    slider_views.addEventListener("input", function() {
      document.getElementById("viewsrange").innerText=slider_views.value + ' Days';
    })
  }
}

function updateCharCount() {
  var characterCount = $('#password_payload').val().length;
  var current = $('#current');
  var maximum = $('#maximum');

  current.text(characterCount);

  if (characterCount >= 1048576) {
    maximum.css('color', '#F91A00');
    current.css('color', '#F91A00');
  }
}

function showDaysValue(newValue)
{
  if (newValue > 1) {
  	document.getElementById("daysrange").innerHTML=newValue + ' Days';
  } else {
  	document.getElementById("daysrange").innerHTML=newValue + ' Day';
  }
}

function showViewsValue(newValue)
{
  if (newValue > 1) {
  	document.getElementById("viewsrange").innerHTML=newValue + ' Views';
  } else {
  	document.getElementById("viewsrange").innerHTML=newValue + ' View';
  }
}

function setCopied() {
	$('#clip_tip').text('copied!');
}

var passwordGeneratorConfig = {
  hasNumbers: true,
  titlecased: true,
  use_separators: true,
  consonants: 'bcdfghklmnprstvz',
  vowels: 'aeiouy',
  separators: '-_=',
  maxSyllableLength: 3,
  minSyllableLength: 1,
  syllablesCount: 3,

  // Defaults
  default_hasNumbers: true,
  default_titlecased: true,
  default_use_separators: true,
  default_consonants: 'bcdfghklmnprstvz',
  default_vowels: 'aeiouy',
  default_separators: '-_=',
  default_maxSyllableLength: 3,
  default_minSyllableLength: 1,
  default_syllablesCount: 3,
};

function configurePasswordGeneratorHooks() {

  // Configure Generator: Generate Password button
  $('#configure_generate_password').on('click', function(e) {
    $('#configure_password_payload').text(generatePassword(passwordGeneratorConfig));
  });

  // hasNumbers
  $('#include_numbers').prop('checked', passwordGeneratorConfig.hasNumbers);
  $('#include_numbers').on('change', function(e) {
    passwordGeneratorConfig.hasNumbers = $('#include_numbers').prop('checked');
  });

  // titlecased
  $('#use_titlecase').prop('checked', passwordGeneratorConfig.titlecased);
  $('#use_titlecase').on('change', function(e) {
    passwordGeneratorConfig.titlecased = $('#use_titlecase').prop('checked');
  });

  // separators
  $('#use_separators').prop('checked', passwordGeneratorConfig.use_separators);
  $('#use_separators').on('change', function(e) {
    passwordGeneratorConfig.use_separators = $('#use_separators').prop('checked');
    // if (passwordGeneratorConfig.use_separators) {
    //   // passwordGeneratorConfig.separators =
    // }
  });

  // num_syllables
  $('#num_syllables').val(passwordGeneratorConfig.syllablesCount)
  $('#num_syllables').on('change input', function(e) {
    var num_syllables_as_int = parseInt($('#num_syllables').val());
    if (typeof num_syllables_as_int === 'number') {
      passwordGeneratorConfig.syllablesCount = num_syllables_as_int;
    }
  });

  // min_syllable_length
  $('#min_syllable_length').val(passwordGeneratorConfig.minSyllableLength)
  $('#min_syllable_length').on('change input', function(e) {
    var min_syllable_length_as_int = parseInt($('#min_syllable_length').val());
    if (typeof min_syllable_length_as_int === 'number') {
      passwordGeneratorConfig.minSyllableLength = min_syllable_length_as_int;
    }
  });

  // max_syllable_length
  $('#max_syllable_length').val(passwordGeneratorConfig.maxSyllableLength)
  $('#max_syllable_length').on('change input', function(e) {
    var max_syllable_length_as_int = parseInt($('#max_syllable_length').val());
    if (typeof max_syllable_length_as_int === 'number') {
      passwordGeneratorConfig.maxSyllableLength = max_syllable_length_as_int;
    }
  });

  // vowels
  $('#vowels').val(passwordGeneratorConfig.vowels)
  $('#vowels').on('change input', function(e) {
    passwordGeneratorConfig.vowels = $('#vowels').val()
  });

  // consonants
  $('#consonants').val(passwordGeneratorConfig.consonants)
  $('#consonants').on('change input', function(e) {
    passwordGeneratorConfig.consonants = $('#consonants').val()
  });

  // separators
  $('#separators').val(passwordGeneratorConfig.separators)
  $('#separators').on('change input', function(e) {
    passwordGeneratorConfig.separators = $('#separators').val()
  });
}


function ready() {
  const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");

  if (prefersDarkScheme.matches) {
    document.body.classList.add('dark-mode')
  }

  restoreFormValuesFromCookie();

  // Primary Clipboard button
  var clipboard_button = new ClipboardJS('#copy-to-clipboard-button');
  clipboard_button.on('success', function(e) {
    var copyIcon = $('#copy-to-clipboard-button').html();
    $('#copy-to-clipboard-button').text('Copied!');
    setTimeout(function() {
      $('#copy-to-clipboard-button').html(copyIcon);
    }, 1000);
    e.clearSelection();
  });

  // Secondary Clipboard button on the Password#Show page
  var clipboard_button_2 = new ClipboardJS('#copy-to-clipboard-button-2');
  clipboard_button_2.on('success', function(e) {
    var copyIcon = $('#copy-to-clipboard-button-2').html();
    $('#copy-to-clipboard-button-2').text('Copied!');
    setTimeout(function() {
      $('#copy-to-clipboard-button-2').html(copyIcon);
    }, 1000);
    e.clearSelection();
  });

  // Generate Password button
  $('#generate_password').on('click', function(e) {
    $('#password_payload').val(generatePassword(passwordGeneratorConfig)).trigger('input');
  });

  configurePasswordGeneratorHooks();

  // "Save these settings as default in a cookie"
  $('#save-defaults').on('click', saveFormValuesToCookie);

  // Range sliders update their labels on change
  setupSliderEventListeners()

  // Password Payload character count
  $('#password_payload').on('change input', updateCharCount);

  // Enable Payload Blur
  spoilerAlert('spoiler, .spoiler', {max: 10, partial: 4});
}

document.addEventListener("DOMContentLoaded", ready);