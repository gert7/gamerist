updatePriceNumbersCallback = (data) ->
  indata = data.data
  $("#paypal_country_small").html("<p>Subtotal: " + indata.subtotal + "</p><p>VAT: " + indata.tax + "</p>")
  $("#paypal_country_total").html(indata.total + " " + indata.currency)
  $("#paypal_country_vatrate").html(indata.vat + "% VAT")
  $("#paypal_country_vatcountry").html(indata.countryname)
  $("#paypal_country_right").children().first().attr("src", "/assets/48/" + indata.countrycode.toLowerCase() + ".png")
  $("#paypal_new_siterate").html(indata.subrate + "%")

updatePriceNumbers = () ->
  $.get("/paydata.json", {"points" : $(".paypal_pointselector").val() }, updatePriceNumbersCallback)

$(document).ready () ->
  if($("#paypal_new"))
    console.log("paypal#new")
    updatePriceNumbers()
    $(".paypal_pointselector").change () ->
      updatePriceNumbers()
