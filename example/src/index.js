/*!
 * Copyright
 */

(function() {
	var hello = 'hello';
	var world = 'world';
	console.log(hello, world);
	if (process.env.NODE_ENV === 'prd') {
		console.log('prd');
	}
})();