$(document).ready(function() {

// General helper function for displaying tooltips
function ShowTooltip(selector) {
    $(selector).mouseover(function() {
        var tooltip_width = $(this).find(".helper_tooltip").width();
        var elem_width = $(this).width();
        $(".helper_tooltip .tooltip_triangle").css("margin-left", "" + (tooltip_width/2 - 10) + "px");
        //$(".helper_tooltip").css("margin-left", "-" + (elem_width/2 + tooltip_width/2) + "px");
    });
}
ShowTooltip(".tooltip_wrapper");
});
