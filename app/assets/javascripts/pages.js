// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready(function() {
  var sim;

  function startBar(progressPercent, CSVrows) {
    var $progressBar = $('.progress-bar');
    var $progress = $('.progress-bar .progress');
    var delay = ((Math.sqrt(progressPercent*2 + 1) * 10)/2) * CSVrows;
    console.log(progressPercent + '%', 'delay:', delay);
    $progress.text(Math.floor(progressPercent*.9) + "%").animate({
      width:  Math.floor(progressPercent*.9) + '%'
    }, delay);
    progressPercent++;
     
    sim = setTimeout(function() {
      startBar(progressPercent, CSVrows);
    }, delay); // 100 milliseconds
     
    if (progressPercent == 100) {
      clearTimeout(sim);
      console.log('hold....');
      $progress.text("90%").animate({
        width: '90%',
      }, delay);
    }
  }

  function finishBar() {
    clearTimeout(sim);

    console.log('complete!');
    var currentProgress = parseInt($('.progress').text());

    $('.progress-bar .progress').text("100%").animate({
      width: '100%',
    }, 500 - currentProgress*5);
  }

  $('.choose-file').click(function() {
    $('#csv_import_file').click();
  });

  $('#csv_import_file').change(function() {
    $('.import-button').prop('disabled', false).removeClass('disabled');
    var path = $('#csv_import_file').val().split('\\');
    var fileName = path[path.length - 1];

    $('.file-name').html(fileName + '<span class="remove-file">X</span>').show();
  });

  $('.file-name').on('click', '.remove-file', function() {
    $('#csv_import_file').val('');
    $('.import-button').prop('disabled', true).addClass('disabled');
    $('.file-name').hide();
  });

  $('.import-button').click(function() {
    if (!$(this).hasClass('disabled')) {

      $('.import-button').prop('disabled', true).addClass('disabled');
      //******* Get the CSV file, read it and parse it with jQuery CSV *******
      var files = $('#csv_import_file')[0].files; // FileList object
      var file = files[0];
      var reader = new FileReader();
      reader.readAsText(file);
      // var uploadFile = new FormData();

      reader.onload = function(event){
        var CSVrows = reader.result.split('\n').length - 1;
        clearTimeout(sim);
        $('.importing-container .importing').text('Importing '+CSVrows+' subscription orders');
        startBar(0, CSVrows);
      };

      // Submit the form
      var uploadFile = new FormData();
      var files = $("#csv_import_file").get(0).files;
      uploadFile.append("CsvDoc", files[0]);

      $.ajax({
        type: "POST",
        contentType: false,
        processData: false,
        url: '/import',
        data: uploadFile
      }).success(function(csv) {

        $('.import-button').prop('disabled', false).removeClass('disabled');
        $('.importing-container .importing').text('Imported '+csv.transactions.length+' subscription orders');
        finishBar();
        console.log(csv);
        var $emptyRow = $($('.import-page').data('empty-transaction-row'))

        successful_transactions = csv.transactions.filter(t => t.status);
        failed_transactions = csv.transactions.filter(t => !t.status);

        function dashIfEmpty(value) {
          if (value) {
            return value;
          } else {
            return '-';
          }
        }

        $('.subs-row').remove();

        if (failed_transactions.length) {
          $('.subs-failed').parent().show().prev().find('.retry-all').show().prev().show();
        } else {
          $('.subs-failed').parent().hide().prev().find('.retry-all').hide().prev().hide();
        }

        failed_transactions.forEach(function(row) {
          var $newRow = $emptyRow.clone();

          $newRow.find('.sub-number').text(dashIfEmpty(row.id));
          $newRow.find('.name').text(dashIfEmpty(row.name));
          $newRow.find('.email').text(dashIfEmpty(row.email));
          $newRow.find('.product').text(dashIfEmpty(row.product));
          if (row.amount) {
            $newRow.find('.amount').text('$' + row.amount.toFixed(2));
          } else {
            $newRow.find('.amount').text('-');
          }
          $newRow.find('.cc_number').text(dashIfEmpty(row.cc_number));
          $newRow.find('.sub-status').text('Failed');

          row.error_codes.forEach(function(error_code) {
            $newRow.find('.errors-list ul').append('<li>'+error_code+'</li>');
            if (row.no_retry) {
              $newRow.find('.errors-row .retry-single').remove();
            }
          });

          $('.subscriptions.subs-failed').append($newRow);
        });

        if (successful_transactions.length) {
          $('.subs-success').parent().show().prev().show();
        } else {
          $('.subs-success').parent().hide().prev().hide();
        }

        successful_transactions.forEach(function(row) {
          var $newRow = $emptyRow.clone();

          $newRow.find('.sub-number').text(row.id);
          $newRow.find('.name').text(row.name);
          $newRow.find('.email').text(dashIfEmpty(row.email));
          $newRow.find('.product').text(row.product);
          $newRow.find('.amount').text('$' + row.amount.toFixed(2));
          $newRow.find('.cc_number').text(row.cc_number);
          $newRow.find('.sub-status').text('Success');

          $newRow.find('.errors-row').remove();

          $('.subscriptions.subs-success').append($newRow);
          $('.import-results-container').show();
        });
      });
    }
  });
});