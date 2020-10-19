$(document).ready(function() {
  $('#selectAll').click(function() {
    if (this.checked) {
      $(':checkbox').each(function() {
        this.checked = true;
      });
    } else {
      $(':checkbox').each(function() {
        this.checked = false;
      });
    }
  });

  $("#edit_multiple_property").click(function(event) {
    // event.preventDefault();
    var checked_pr_array = [];
    $('#properties_table :checked').each(function() {
      checked_pr_array.push($(this).val());
    });
    var url = $(this).attr('href');
    $.ajax({
      url: url,
      data: {
        property_ids: checked_pr_array
      },
      type: "GET",
      success: function(response) {
        //console.log(response)
      },
      error: function(xhr, textStatus, errorThrown) {}
    });
  });
  // $("#edit_multiple_form_submit").click(function(event) {
  //   console.log('click');
  //   event.preventDefault();
  //   //console.log('click');
  //   $("#form_edit_multi").submit();
  //   $('#modal-edit').modal('hide');
  //   location.reload();
  // });

  $('#deleteAllproperty').click(function() {
    // event.preventDefault();
    var array = [];
    $('#properties_table :checked').each(function() {
      array.push($(this).val());
    });

    $.ajax({
      type: "POST",
      url: $(this).attr('href') + '.json',
      data: {
        ids: array
      },
      beforeSend: function() {
        return confirm("Вы уверенны?");
      },
      success: function(data, textStatus, jqXHR) {
        if (data.status === 'ok') {
          //alert(data.message);
          location.reload();
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        console.log(jqXHR);
      }
    })

  });


});