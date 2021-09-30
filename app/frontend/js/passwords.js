import 'spoiler-alert/spoiler'

import Cookies from 'js-cookie'
import PasswordGenerator from '../js/pw_generator'
import setupClipboardButton from './clipboard_buttons'
import toBoolean from '../js/toolbox'

function restoreFormValuesFromCookie() {

  let default_days_expiration = $('#password_expire_after_days').attr('x_default');
  let days_expiration = Cookies.get('pwpush_days') || default_days_expiration;

  $('#password_expire_after_days').val(days_expiration);
  updateDaysSlider(days_expiration);

  let default_views_expiration = $('#password_expire_after_views').attr('x_default');
  let views_expiration = Cookies.get('pwpush_views') || default_views_expiration;

  $('#password_expire_after_views').val(views_expiration);
  updateViewsSlider(views_expiration);

  let default_deleteable_by_viewer = $('#password_deletable_by_viewer').attr('x_default');
  let deletable_by_viewer = Cookies.get('pwpush_dbv');

  if (deletable_by_viewer) {
    $('#password_deletable_by_viewer').prop('checked', toBoolean(deletable_by_viewer));
  } else {
    $('#password_deletable_by_viewer').prop('checked', default_deleteable_by_viewer);
  }

  let default_retrieval_step = $('#password_retrieval').attr('x_default');
  let retrieval_step = Cookies.get('pwpush_retrieval');

  if (retrieval_step) {
    $('#password_retrieval_step').prop('checked', toBoolean(retrieval_step));
  } else {
    $('#password_retrieval_step').prop('checked', default_retrieval_step);
  }
}

function saveFormValuesToCookie() {
  Cookies.set('pwpush_days', $('#password_expire_after_days').val(), { expires: 365 });
  Cookies.set('pwpush_views', $('#password_expire_after_views').val(), { expires: 365 });
  Cookies.set('pwpush_dbv', $('#password_deletable_by_viewer').prop('checked').toString(), { expires: 365 });
  Cookies.set('pwpush_retrieval', $('#password_retrieval_step').prop('checked').toString(), { expires: 365 });

  $('#cookie-save').html('Saved!  <em>Defaults updated.</em>');
  return true;
}

function updateDaysSlider(days) {
  if (days > 1) {
    $('#daysrange').text(days + $('#lang_days').text());
  } else {
    $('#daysrange').text(days + $('#lang_day').text());
  }
}

function updateViewsSlider(views) {
  if (views > 1) {
    $('#viewsrange').text(views + $('#lang_views').text());
  } else {
    $('#viewsrange').text(views + $('#lang_view').text());
  }
}

function setupSliderEventListeners()
{
  $('#password_expire_after_days').on('change input', function() {
    updateDaysSlider(this.value);
  });

  $('#password_expire_after_views').on('change input', function() {
    updateViewsSlider(this.value);
  });
}

function ready() {
  const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");

  if (prefersDarkScheme.matches) {
    document.body.classList.add('dark-mode')
  }

  restoreFormValuesFromCookie();

  setupClipboardButton('#copy-to-clipboard-button');
  setupClipboardButton('#copy-to-clipboard-button-2');

  PasswordGenerator.onReady();

  // "Save these settings as default in a cookie"
  $('#save-defaults').on('click', saveFormValuesToCookie);

  // Range sliders update their labels on change
  setupSliderEventListeners()

  // Password Payload character count
  $('#password_payload').on('change input', function() {
    var characterCount = $('#password_payload').val().length;
    var current = $('#current');
    var maximum = $('#maximum');

    current.text(characterCount);

    if (characterCount >= 1048576) {
      maximum.css('color', '#F91A00');
      current.css('color', '#F91A00');
    }
  });

  // Enable Payload Blur
  spoilerAlert('spoiler, .spoiler', {max: 10, partial: 4});
}

document.addEventListener("DOMContentLoaded", ready);