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
	}, 5000);
});

