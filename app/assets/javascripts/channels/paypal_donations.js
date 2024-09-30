const paypalDonationsChannelEvents = {
  made: 'made'
}

function initPaypalDonationsChannel(id) {
  return initChannel('PaypalDonationsChannel', {data: id});
}
