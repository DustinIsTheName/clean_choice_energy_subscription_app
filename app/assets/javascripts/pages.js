// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready(function() {

  $('#csv_import_file').change(function() {

    //******* Get the CSV file, read it and parse it with jQuery CSV *******
    var files = this.files; // FileList object
    var file = files[0];
    var reader = new FileReader();
    reader.readAsText(file);
    // var uploadFile = new FormData();

    reader.onload = function(event){
      var csv = event.target.result;
      var data = $.csv.toObjects(csv);
    };

    // Submit the form
    var uploadFile = new FormData();
    var files = $("#csv_import_file").get(0).files;

    uploadFile.append("CsvDoc", files[0]);
    uploadFile.append("stripe_token", $('[name="stripeToken"]').val());

    $.ajax({
      type: "POST",
      contentType: false,
      processData: false,
      url: '/import',
      data: uploadFile
    }).success(function(csv) {
      console.log(csv);
      $('#csv_import_file').val('');

      $('body').append('<ul><h4>Import</h4></ul>');

      csv.transactions.forEach(function(row) {
        for (key in row) {
          $('body ul').append('<li>'+key+': '+row[key]+'</li>')
        }
      });
    });
  });
});