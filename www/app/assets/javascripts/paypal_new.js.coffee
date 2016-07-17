updatePriceNumbersCallback = (data) ->
  console.log(data.uniquesignature)
  if data.uniquesignature != CURRENT_UNIQUE_SIGNATURE
    return false
  indata = data.data
  $("#paypal_country_small").html("<p>Subtotal: " + indata.subtotal + "</p><p>Sales tax: " + indata.tax + "</p>")
  $("#paypal_country_total").html(indata.total + " " + indata.currency)
  $("#paypal_country_euro_total").html(indata.total_eur + " EUR")
  $("#paypal_country_vatrate").html(indata.vat + "% VAT")
  $("#paypal_country_vatcountry").html(indata.countryname)
  $("#paypal_country_right").children().first().attr("src", "/assets/48/" + indata.countrycode.toLowerCase() + ".png")
  $("#paypal_new_siterate").html(indata.subrate + "%")

random_unique_signature = () ->
  text = ""
  possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  for i in [0..7]
    text += possible.charAt(Math.floor(Math.random() * possible.length));
  return text

CURRENT_UNIQUE_SIGNATURE = "ffff01"

updatePriceNumbers = () ->
  CURRENT_UNIQUE_SIGNATURE = random_unique_signature()
  $.get("/paydata.json", {"points" : $(".paypal_pointselector").val(), "unique_signature": CURRENT_UNIQUE_SIGNATURE}, updatePriceNumbersCallback)

$(document).ready () ->
  if($("#paypal_new").length)
    console.log("paypal#new")
    updatePriceNumbers()
    $(".paypal_pointselector").change () ->
      updatePriceNumbers()
