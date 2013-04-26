$("[data-append],[data-replace],[data-after],[data-before]").ajaxInclude();

$(document).ready(function(){
	$('#flynn1').flynn();
	$('#flynn2').flynn();
});

$(".logo").draggable({ revert: true });