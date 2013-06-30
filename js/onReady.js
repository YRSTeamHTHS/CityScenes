function updateRangeInput(val) {
	var text=''
	if (val==1) {
		text=val.toString() + ' Destination';
	} else {
		text=val.toString() + ' Destinations';
	}
    document.getElementById('rangeTextVal').innerHTML=text; 
}
$(document).ready(function(){
	/*$("#btn-side-menu-toggle").click(function(){
		$("#side-menu").toggleClass("visible-menu");
		$("#side-menu").toggleClass("hidden-menu");
	});*/
});