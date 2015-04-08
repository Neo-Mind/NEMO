String.prototype.replaceAt = function(index, rstring) {
	if (index < 0)
    index = this.length + index;
  return (this.substring(0,index) + rstring + this.substring(index + rstring.length));
}

String.prototype.repeat = function(num) {
  var result = '';
  for (var i=0; i<num; i++) {
    result += this.toString();
  }
  return result;
}

String.prototype.hexlength = function() {
	var l=this.replace(/ /g, "").length;
	if (l%2 !== 0) l++;
	return l/2;
}

String.prototype.toHex = function() {
  var result = '';
  for (var i = 0; i < this.length; i++) {
  	var h = this.charCodeAt(i).toString(16);
    if (h.length === 1)
  		h = '0' + h;
    result += ' ' + h;
  }
  return result;
}

String.prototype.toHexUC = function() {
  var result = '';
  for (var i = 0; i < this.length; i++) {
    var h = this.charCodeAt(i).toString(16);
    if (h.length === 1)
  	  h = '0' + h;
    result += ' 00 ' + h;
  }
  return result;
}

String.prototype.toAscii = function() {
  var result = '';
  var splits = this.trim().split(' ');
  for (var i = 0; i < splits.length; i++) {
    var h = parseInt(splits[i], 16);
    result += String.fromCharCode(h);
  }
  return result;
}

String.prototype.unpackToInt = function() {
	var orig = this;
	return parseInt("0x" + orig.split(" ").reverse().join(""),16);
}

Number.prototype.packToHex = function(size) {
	var number = this;
	if (number < 0)
		number = 0xFFFFFFFF + number + 1;
	
	if (size > 4)
		size = 4;
	
	var hex = number.toString(16);
	size  = size * 2;
	
	if (hex.length > size)
		hex = hex.substr( hex.length - size);
	
	while (hex.length < size) {
		hex = "0" + hex;
	}
	
	var result = "";
	while (hex !== "") {
		result = " " + hex.substr(0,2) + result;
		hex = hex.substr(2);
	}
	
	return result;
}