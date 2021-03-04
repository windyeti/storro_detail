$(document).ready(function() {
  App.cable.subscriptions.create({channel: 'NotificationChannel'}, {
    connected: function() {
      this.perform('follow')
    },
    received: function(data) {
      $('.process_start').remove();
      $('body').prepend("<div>>>>>>>>>>>>>> ЗАКОНЧЕН " + data.process_name +"<<<<<<<<<<<<<<<<<<<<<</div>")
    }
  });
});
