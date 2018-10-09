// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

function ready() {
  var sim;

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

  function startBar(progressPercent, CSVrows) {
    var $progressBar = $('.progress-bar');
    var $progress = $('.progress-bar .progress');
    var delay = ((Math.sqrt(progressPercent*2 + 1) * 10)/2) * CSVrows;
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
      $('.import-results-container').prev().show();

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

  /***** Subscriptions PAGE *****/

  $('#reveal-add-single-subscription').click(function() {
    $('.add-container').slideToggle();
  });

  $('.email-filter li').click(function() {
    var filter = $(this).data('filter');

    $('.email-filter li').removeClass('active');
    $(this).addClass('active');

    $('.subscriptions').removeClass('hide-email hide-no-email');
    $('.subscriptions').addClass(filter);
  });

  $('#add-single-subscription').click(function() {
    var row = {}

    $('#add-single-subscription').addClass('is-loading');

    $('.single-subscription-field').each(function() {
      row[$(this).attr('name')] = $(this).val();
    });

    $.ajax({
      type: "POST",
      url: '/single',
      data: {row: row}
    }).success(function(single_import) {
      console.log(single_import);
      var transaction = single_import.transactions[0]

      $('.errors-row').remove();
      if (transaction.error_codes.length) {

        html = '<div class="errors-row clearfix">';
        html +=   '<div class="errors-bar align-left">';
        html +=     '<div class="errors-title">Error Code(s)</div>';
        html +=     '<div class="errors-list">';
        html +=       '<ul class="clearfix">';
        for (var i = 0; i < transaction.error_codes.length; i++) {
        html +=         '<li>'+transaction.error_codes[i]+'</li>';
        }
        html +=       '</ul>';
        html +=     '</div>';
        html +=   '</div>';
        html += '</div>';

        $('.add-container').append(html);

      } else {
        var $emptyRow = $($('.subscription-page').data('empty-subscription-row'));
        var $newRow = $emptyRow.clone();

        var date = new Date(transaction.created_at).toLocaleString('en-US', {day: 'numeric', month: 'numeric', year: '2-digit', hour: 'numeric', minute: 'numeric'}).toLowerCase().replace(' pm', 'pm');

        if (transaction.email) {
          $newRow.addClass('email').removeClass('no-email');
          $newRow.attr('data-sub-id', transaction.subscription_id);
        }

        $newRow.find('.sub-number').text(transaction.subscription_id);
        $newRow.find('.name').text(transaction.name);
        $newRow.find('.email').text(dashIfEmpty(transaction.email));
        $newRow.find('.product').text(transaction.product);
        $newRow.find('.amount').text('$' + transaction.amount.toFixed(2));
        $newRow.find('.cc_number').text('-'+transaction.cc_number);
        $newRow.find('.sub-date').text(date);

        console.log(transaction);

        $('.subscriptions .subs-header').after($newRow);
      }
      $('#add-single-subscription').removeClass('is-loading');
    });
  });

  $('body').on('click', '.button-edit', function(e) {
    e.preventDefault();
    var $subsRow = $(this).closest('.subs-row');
    var firstName = $subsRow.find('.name .first').text();
    var lastName = $subsRow.find('.name .last').text();
    var email = $subsRow.find('.email').text();

    if (!firstName || !lastName) {
      var nameArray = $subsRow.find('.name').text().split(' ');
      lastName = nameArray.pop();
      firstName = nameArray.join(' ');
    }
    if (email === '-') {
      email = '';
    }
      var $this = $(this);

    $subsRow.find('.button-edit').hide();
    $subsRow.find('.button-delete').hide();
    $subsRow.find('.button-edit-save').show();

    $subsRow.find('.name').html('<input class="single-subscription-field" name="first-name" placeholder="First Name" value="'+firstName+'"><input class="single-subscription-field" name="last-name" placeholder="Last Name" value="'+lastName+'">');
    $subsRow.find('.email').html('<input class="single-subscription-field" name="email" placeholder="Email" value="'+email+'">');
  });

  $('body').on('click', '.button-edit-save', function(e) {
    e.preventDefault();
    var $subsRow = $(this).closest('.subs-row');

    if (!$subsRow.find('.button-edit-save').hasClass('is-loading')) {
      $subsRow.find('.button-edit-save').addClass('is-loading');
      var sub_id = $subsRow.attr('data-sub-id');

      $.ajax({
        type: "POST",
        url: '/edit',
        data: {
          subscription_id: sub_id,
          first_name: $subsRow.find('[name="first-name"]').val(),
          last_name: $subsRow.find('[name="last-name"]').val(),
          email: $subsRow.find('[name="email"]').val()
        }
      }).success(function(response) {
        console.log(response);

        $subsRow.find('.button-edit-save').removeClass('is-loading').hide();
        $subsRow.find('.button-delete').show();
        $subsRow.find('.button-edit').show();
        $subsRow.find('.name').html('<span class="first">'+response.first_name+'</span> <span class="last">'+response.last_name+'</span>');
        $subsRow.find('.email').html(response.email);
      });
    }
  });

  $('body').on('click', '.button-delete', function(e) {
    var $this = $(this);

    if (confirm("Are you sure you want to delete the customer "+$this.closest('.subs-row').find('.name').text())) {
      e.preventDefault();
      var sub_id = $this.closest('.subs-row').attr('data-sub-id');

      if (!$this.hasClass('is-loading')) {
        $this.addClass('is-loading');

        $.ajax({
          type: "POST",
          url: '/delete',
          data: {subscription_id: sub_id}
        }).success(function(response) {
          console.log(response);

          $this.closest('.subs-row').remove();
        });
      }
    }
  });

  var page = 1;
  var search = '';

  $('body').on('click', '.load-more', function(e) {
    if (!$('.load-more').hasClass('is-loading')) {
      $('.load-more').addClass('is-loading');
      page++;

      console.log(search);

      $.ajax({
        type: "GET",
        url: '/subscription_page',
        data: {
          page: page,
          search: search
        }
      }).success(function(pagination) {
        console.log(pagination);
        $('.load-more').removeClass('is-loading');
        $('.subscriptions').append(pagination.html);

        if (pagination.load_more) {
          $('.load-more').show();
        } else {
          $('.load-more').hide();
        }
      });
    }
  });

  $('body').on('keyup', '.search-input', function(e) {
    console.log('d');
    $('.search').removeClass('reset');
  });

  $('body').on('click', '.search', function(e) {
    if (!$('.search').hasClass('is-loading')) {

      if (!$('.search').hasClass('reset')) {

        $('.subscriptions-filter-label').text('Searching by:');
        $('.search').addClass('is-loading');

        page = 1;
        search = $('.search-input').val();

        $.ajax({
          type: "GET",
          url: '/subscription_page',
          data: {
            page: page,
            search: search
          }
        }).success(function(pagination) {
          console.log(pagination);
          $('.search').removeClass('is-loading').addClass('reset');
          $('.subscriptions .subs-row').remove();
          if (pagination.html) {
            $('.subscriptions').append(pagination.html);
          } else {
            $('.subscriptions').append('<div class="subs-row clearfix" style="padding: 21px 20px 19px;text-align: center;">No results for "'+search+'".</div>');
          }

          if (pagination.load_more) {
            $('.load-more').show();
          } else {
            $('.load-more').hide();
          }
        });
      } else {
        search = '';

        $('.search-input').val('');
        $('.subscriptions-filter-label').text('Search by Customer Name');

        $.ajax({
          type: "GET",
          url: '/subscription_page',
          data: {
            page: page,
            search: search
          }
        }).success(function(pagination) {
          console.log(pagination);
          $('.search').removeClass('is-loading').removeClass('reset');
          $('.subscriptions .subs-row').remove();
          if (pagination.html) {
            $('.subscriptions').append(pagination.html);
          } else {
            $('.subscriptions').append('<div class="subs-row clearfix" style="padding: 21px 20px 19px;text-align: center;">No results for "'+search+'".</div>');
          }

          if (pagination.load_more) {
            $('.load-more').show();
          } else {
            $('.load-more').hide();
          }
        });
      }
    }
  });

  /***** USERS PAGE *****/

  $('#reveal-add-user').click(function() {
    $('.add-container').slideToggle();
  });

  $('#add-user').click(function() {
    var user = {}

    $('#add-user').addClass('is-loading');

    $('.single-user-field').each(function() {
      user[$(this).attr('name')] = $(this).val();
    });

    $.ajax({
      type: "POST",
      url: '/user',
      data: {user: user}
    }).success(function(user) {
      console.log(user);

      $('.errors-row').remove();
     
      if (user.errors) {

        html = '<div class="errors-row clearfix">';
        html +=   '<div class="errors-bar align-left">';
        html +=     '<div class="errors-title">Error Code(s)</div>';
        html +=     '<div class="errors-list">';
        html +=       '<ul class="clearfix">';
        for (key in user.errors) {
        html +=         '<li>'+key+' '+user.errors[key][0]+'</li>';
        }
        html +=       '</ul>';
        html +=     '</div>';
        html +=   '</div>';
        html += '</div>';

        $('.add-container').append(html);
        console.log(user);
      } else {

        var $emptyRow = $($('.user-page').data('empty-user-row'));
        var $newRow = $emptyRow.clone();

        $newRow.attr('data-user-id', user.id);
        $newRow.find('.users-number').text(user.id);
        $newRow.find('.users-name').text(user.first_name + ' ' + user.last_name);
        $newRow.find('.users-email').text(user.email);
        $newRow.find('.users-access').text(user.access);

        console.log(user);

        $('.user-page .users').append($newRow);
      }

      $('#add-user').removeClass('is-loading');
    });
  });

  $('body').on('click', '.button-user-edit', function(e) {
    console.log('yyyyyyy')
    e.preventDefault();
    var $userRow = $(this).closest('.users-row');
    var firstName = $userRow.find('.users-name .first').text();
    var lastName = $userRow.find('.users-name .last').text();
    var email = $userRow.find('.users-email').text();
    var access = $userRow.find('.users-access').text().toLowerCase().split(' ').join('_');

    if (!firstName || !lastName) {
      var nameArray = $userRow.find('.users-name').text().split(' ');
      lastName = nameArray.pop();
      firstName = nameArray.join(' ');
    }

    if (email === '-') {
      email = '';
    }
    var $this = $(this);

    console.log(access)

    var access_html = '<select name="access" class="single-user-field">';
    if (access == 'admin') {
      access_html += '<option selected="true" value="admin">Admin</option>';
    } else {
      access_html += '<option value="admin">Admin</option>';
    }
    if (access == 'customer_care') {
      access_html += '<option selected="true" value="customer_care">Customer Care</option>';
    } else {
      access_html += '<option value="customer_care">Customer Care</option>';
    }
    if (access == 'importer') {
      access_html += '<option selected="true" value="importer">Importer</option>';
    } else {
      access_html += '<option value="importer">Importer</option>';
    }
    access_html += '</select>';

    $userRow.find('.button-user-edit').hide();
    $userRow.find('.button-user-delete').hide();
    $userRow.find('.button-user-edit-save').show();


    $userRow.find('.users-name').html('<input class="single-user-field" name="first-name" placeholder="First Name" value="'+firstName+'"><input class="single-user-field" name="last-name" placeholder="Last Name" value="'+lastName+'">');
    $userRow.find('.users-email').html('<input class="single-user-field" name="email" placeholder="Email" value="'+email+'">');

    $userRow.find('.users-access').addClass('edit').html(access_html);
  });



  $('body').on('click', '.button-user-edit-save', function(e) {
    e.preventDefault();
    var $userRow = $(this).closest('.users-row');

    if (!$userRow.find('.button-user-edit-save').hasClass('is-loading')) {
      $userRow.find('.button-user-edit-save').addClass('is-loading');
      var user_id = $userRow.attr('data-user-id');

      $.ajax({
        type: "POST",
        url: '/edit-user',
        data: {
          user_id: user_id,
          first_name: $userRow.find('[name="first-name"]').val(),
          last_name: $userRow.find('[name="last-name"]').val(),
          email: $userRow.find('[name="email"]').val(),
          access: $userRow.find('[name="access"]').val()
        }
      }).success(function(response) {
        console.log(response);

        String.prototype.capitalize = function() {
          return this.charAt(0).toUpperCase() + this.slice(1);
        }

        $userRow.find('.button-user-edit-save').removeClass('is-loading').hide();
        $userRow.find('.button-user-delete').show();
        $userRow.find('.button-user-edit').show();
        $userRow.find('.users-name').html('<span class="first">'+response.first_name+'</span> <span class="last">'+response.last_name+'</span>');
        $userRow.find('.users-email').html(response.email);
        $userRow.find('.users-access').removeClass('edit').html(response.access.capitalize().split('_').join(' '));
      });
    }
  });




  $('body').on('click', '.button-user-delete', function(e) {
    var $this = $(this);

    if (confirm("Are you sure you want to delete this user "+$this.closest('.subs-row').find('.users-name').text())) {
      e.preventDefault();
      var usr_id = $this.closest('.users-row').attr('data-user-id');

      if (!$this.hasClass('is-loading')) {
        $this.addClass('is-loading');

        $.ajax({
          type: "POST",
          url: '/delete-user',
          data: {user_id: usr_id}
        }).success(function(response) {
          console.log(response);

          $this.closest('.users-row').remove();
        });
      }
    }
  });
}

$(document).on('turbolinks:load', ready);
// $(document).ready(ready);





























