$(document).ready(function() {
  App.cable.subscriptions.create({channel: 'StartChannel'}, {
    connected: function() {
      this.perform('follow')
    },
    received: function(data) {
      console.log(data);
      $('.modal').css({"display": "block",  "opacity": "1"}).find('.modal-body').html('Запущен процесс: '+data.process_name);
      $('.modal').find('.modal-header, .modal-body').css({"background-color": "red", "color": "white"})
    }
  });
});
