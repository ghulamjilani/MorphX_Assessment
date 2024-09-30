window.websocketPaypalDonationListener = function() {
  if (typeof(window.donationAmountView) != 'undefined') {
    var attrs = donationAmountView.model.attributes;

    window.paypalDonationsChannel = initPaypalDonationsChannel(attrs['abstract_session_id'])
    window.paypalDonationsChannel.bind('made', (data) => {
      window.donationAmountView.reload();
    });
  }
}
