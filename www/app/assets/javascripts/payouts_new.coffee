updatePayoutNumbersCallback = (data) ->
  indata = data.data
  modifs = indata.modifiers
  $("#payout_withdrawal_fee").text(0 - (modifs.filter (x) -> x.name == "Fixed withdrawal fee")[0].amount)
  $("#payout_modifiers_list").html("")
  for m in modifs
    $("#payout_modifiers_list").append("<div class='payout_modifiers_list_left'>" + m.name + ":</div><div class='payout_modifiers_list_right'>" + m.amount + "</div>")
  $("#payout_euro_total").html("€" + indata.total)

updatePayoutNumbers = () ->
  $.get("/payoutdata.json", {"points" : $(".paypal_pointselector").val() }, updatePayoutNumbersCallback)

$(document).ready () ->
  if($("#payout_new").length)
    console.log("payout#new")
    updatePayoutNumbers()
    $(".paypal_pointselector").change () ->
      updatePayoutNumbers()
      
