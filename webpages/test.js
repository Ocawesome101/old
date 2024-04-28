// set of simple utility functions
function set(id,text) {
	document.getElementById(id).innerHTML = text
}

function hide(id) {
	document.getElementById(id).style.display = 'none'
}

function show(id) {
	document.getElementById(id).style.display = 'block'
}

function alarm(text) {
	window.alert(text)
}

function output(text) {
	console.log(text)
}