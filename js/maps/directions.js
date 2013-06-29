var dir;
$(document).ready(function() {
$.getJSON('http://maps.googleapis.com/maps/api/directions/json?origin=Chicago,IL&destination=Los+Angeles,CA&waypoints=Joplin,MO|Oklahoma+City,OK&sensor=false&mode=bicycling',function(data) {
	console.log(data.routes[0].legs[0].distance);
	console.log(data);
	var leg_distance = [];
	var leg_duration = [];
	var leg_start = [];
	var leg_end = [];
	$.each(data.routes[0].legs, function(i, legs){
		leg_distance[i] = legs.distance.text;
		leg_duration[i] = legs.duration.text;
		leg_start[i] = legs.start_address;
		leg_end[i] = legs.end_address;
		//var wrap = '<span class="distance"></span><span class="duration"></span><span class="start"></span></li>'
		//var step_instr[i] = [];
		//$(wrap).appendTo('body');
		//$('span.distance').html(legs.distance.text);
		//$('span.duration').html(legs.duration.text);
		
		$.each(legs.steps, function (j, steps){
			//step_distance[i][j] = steps.distance.text;
			//step_duration[i][j] = steps.duration.text;
			//step_instr[i][j] = steps.html_instructions.text;
			var step_wrap = "<li>"+steps.html_instructions+'<br/><div class="distance" style="text-align:right">'+steps.distance.text+" - about "+steps.duration.text+"</div></li>"
			$(step_wrap).appendTo('ol.directions');
		})
	});
	
	})
	})