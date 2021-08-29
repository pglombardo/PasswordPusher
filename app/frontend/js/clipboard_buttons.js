import ClipboardJS from 'clipboard'

export default function setupClipboardButton(id) {
    var clipboard_button = new ClipboardJS(id);
    clipboard_button.on('success', function(e) {
      var copyIcon = $(id).html();
      $(id).text('Copied!');
      setTimeout(function() {
        $(id).html(copyIcon);
      }, 1000);
      e.clearSelection();
    });
}