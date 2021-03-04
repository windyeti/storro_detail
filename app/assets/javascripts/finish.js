$(document).ready(function() {
  App.cable.subscriptions.create({channel: 'FinishChannel'}, {
    connected: function() {
      this.perform('follow')
    },
    received: function(data) {
      $('.process_start').remove();
      $('.modal').find('.modal-body').html('Завершен процесс: '+data.process_name);
      $('.modal').find('.modal-header, .modal-body').css({"background-color": "green", "color": "white"})
    }
  });
});
