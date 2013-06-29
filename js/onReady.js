$(document).ready(function(){
	$("#btn-side-menu-toggle").click(function(){
		var text = $(this).text();
		//alert(text);
		/*if (text==";lsaquo;lsaquo") {
			alert(1);
		} else {
		
		}*/
		$("#side-menu").toggleClass("visible-menu");
		$("#side-menu").toggleClass("hidden-menu");
	});
});