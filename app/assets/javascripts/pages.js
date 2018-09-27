// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function ready() {
  var sim;

  function startBar(progressPercent, CSVrows) {
    var $progressBar = $('.progress-bar');
    var $progress = $('.progress-bar .progress');
    var delay = ((Math.sqrt(progressPercent*2 + 1) * 10)/2) * CSVrows;
    console.log(progressPercent + '%', 'delay:', delay);
    $progress.text(Math.floor(progressPercent*.92) + "%").animate({
      width:  Math.floor(progressPercent*.92) + '%'
    }, delay);
    progressPercent++;
     
    sim = setTimeout(function() {
      startBar(progressPercent, CSVrows);
    }, delay); // 100 milliseconds
     
    if (progressPercent == 100) {
      clearTimeout(sim);
      console.log('hold....');
      $progress.text("92%").animate({
        width: '92%',
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
      $('.import-results-container').show();

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

        function add(a, b) {
          if (a && b) {
            return a + b; 
          } else if (a) {
            return a;
          } else if (b) {
            return b;
          }
        }

        $('.subs-row').remove();

        if (failed_transactions.length) {
          $('.subs-failed').parent().show().prev().show();

          $('.transactions-failed .transaction-qty').text(failed_transactions.length + ' of ' + csv.transactions.length);
          var failed_total = failed_transactions.map(function(t) {
            return t.amount
          }).reduce(add, 0);
          $('.transactions-failed .transaction-sales').text('$'+failed_total.toFixed(2));

          $('.transactions-failed').show();
        } else {
          $('.subs-failed').parent().hide().prev().hide();
          $('.transactions-failed').hide();
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

          $('.transactions-success .transaction-qty').text(successful_transactions.length + ' of ' + csv.transactions.length);
          var success_total = successful_transactions.map(function(t) {
            return t.amount
          }).reduce(add, 0);
          $('.transactions-success .transaction-sales').text('$'+success_total.toFixed(2));

          $('.transactions-success').show();
        } else {
          $('.subs-success').parent().hide().prev().hide();
          $('.transactions-success').hide();
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

  $('.log-details .details').click(function() {
    $(this).toggleClass('hide');
    $(this).closest('.log-row').toggleClass('showing-details');
    $(this).parent().next('.log-accordion-details').slideToggle();
  });

  $('.log-filter-date-start, .log-filter-date-end').change(function() {
    $('.log-filter-form button').removeClass('reset');
  });

  $('.log-filter-form button').click(function() {
    var startInput = $('.log-filter-date-start').val();
    var endInput = $('.log-filter-date-end').val();
    var hideCount = 0;

    $('.log-error').remove();

    if ($(this).hasClass('reset')) {
      $('.log-filter-label').text('Filter by date range');
      $('.log-filter-form button').removeClass('reset');
      $('.log-filter-date-start').val('');
      $('.log-filter-date-end').val('');
      $('.log-date, .log-row').show();
    } else {

      if (startInput && endInput) {
        var start, end;
        var st = parseInt(startInput.split('-').join(''));
        var en = parseInt(endInput.split('-').join(''));

        if (st > en) {
          start = en;
          end = st;
        } else {
          start = st;
          end = en;
        }

        $('.log-date, .log-row').each(function() {
          var rowDate = $(this).data('date');

          if (rowDate >= start && rowDate <= end) {
            $(this).show();
          } else {
            $(this).hide();
            hideCount++;
          }
        });

        $('.no-event-within-ranged').remove();
        if (hideCount >= $('.log-date, .log-row').length) {
          $('.log-container').append('<div class="no-event-within-ranged page-title">There is nothing to show for the selected dates.</div>')
        }

        $('.log-filter-label').text('Filtering by date range:');
        $('.log-filter-form button').addClass('reset');

      } else if (startInput) {
        $('.log-filter').append('<div class="log-error">Please choose an end date.</div>');
      } else if (endInput) {
        $('.log-filter').append('<div class="log-error">Please choose a start date.</div>');
      } else {
        $('.log-filter').append('<div class="log-error">Please choose a start and end date.</div>');
      }
    }

  });
}

$(document).on('turbolinks:load', ready);
// $(document).ready(ready);





























