function showCounter(endDate) {
  var curt = Date.now();
  console.log(endDate - curt);
  if(endDate > curt) {
    var diff = new Date(endDate - curt);
    $("#pepsiyolo_counter").text(diff.getUTCHours().toString() + ":" + diff.getUTCMinutes().toString() + ":" + diff.getUTCSeconds().toString());
    setTimeout(function(){showCounter(endDate)}, 200);
  }
  else {
    $("#pepsiyolo_counter").hide();
    $("#pepsiyolo").show();
  }
}

$(document).ready(function () {
  var smode = 0;
	setInterval(function() {
    smode++;
		$("#fg_slideshow_icon").animate({
			'background-position': '-=52px'
		}, 1000);
		$("#fg_slideshow_image").animate({
			'background-position': '-=355px'
		}, 1000);
		$("#fg_slideshow_text_inner").animate({
			'boxShadow': '-4px 4px #b8a759'
		}, 1000);
    console.log(smode);
    if(smode % 2 == 1) {
		  $("#fg_slideshow_text_inner_content1").fadeOut();
		  $("#fg_slideshow_text_inner_content2").fadeIn();
    }
    else
    {
		  $("#fg_slideshow_text_inner_content1").fadeIn();
		  $("#fg_slideshow_text_inner_content2").fadeOut();
    }
	}, 3000);

  $("#pepsiyolo").click(function() {
    $(this).hide();
    $.ajax({
  url: "/",
  type: "POST",
  beforeSend: function( xhr ) {
    xhr.overrideMimeType( "text/plain; charset=x-user-defined" );
  }
})
  .done(function( data ) {
    if ( console && console.log ) {
      $("#pepsiyolo_counter").show();
      var endtime = Date.now() + $.parseJSON(data).seconds * 1000;
      showCounter(endtime);
    }
  });
  });
});
