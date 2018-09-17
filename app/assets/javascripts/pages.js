// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready(function() {

  $('#csv_import_file').change(function() {

    // var reader = new FileReader();
    // var file = this.files[0];
    // fd.append('file', this.files[0]);

    // reader.onload = function(event) {
    //   var csvData = event.target.result;
    //   cb(csvToJson(parsed.data));
    // };

    var uploadFile = new FormData();
    var files = $("#csv_import_file").get(0).files;

    uploadFile.append("CsvDoc", files[0]);

    console.log(uploadFile);

    $.ajax({
      type: "POST",
      contentType: false,
      processData: false,
      url: '/import',
      data: uploadFile
    }).success(function(csv) {
      console.log(csv);
    });

    console.log(this.files);
  });

});