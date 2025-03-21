/*
 * HTML Parser By John Resig (ejohn.org)
 * Original code by Erik Arvidsson, Licensed under the Apache License, Version 2.0 or Mozilla Public License
 * http://erik.eae.net/simplehtmlparser/simplehtmlparser.js

 * added support of HTML5 by Krzysztof Różalski <cristo.rabani@gmail.com>
 */

// Regular Expressions for parsing tags and attributes (modified attribute name matcher, to catch xml:lang)
var startTag = /^<([\w-]+\:?\w*)((?:\s+[a-zA-Z_:-]+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')|[^>\s]+))?)*)\s*(\/?)>/,
	endTag = /^<\/([\w-]+)[^>]*>/,
	attr = /([\w-]+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')|([^>\s]+)))?/g;

function makeMap(str){
	var obj = {}, items = str.split(",");
	for ( var i = 0; i < items.length; i++ )
		obj[ items[i] ] = true;
	return obj;
}

var empty = makeMap("area,base,basefont,br,col,frame,hr,img,input,isindex,keygen,link,meta,menuitem,source,track,param,embed,wbr");

var block = makeMap("article,aside,address,applet,blockquote,button,canvas,center,dd,del,dir,div,dl,dt,fieldset,figcaption,figure,form,footer,frameset,hr,iframe,header,hgroup,ins,isindex,li,map,menu,noframes,noscript,object,ol,output,p,pre,progress,section,script,table,tbody,td,tfoot,th,thead,tr,ul,video");

var inline = makeMap("a,abbr,acronym,applet,audio,b,basefont,bdo,big,br,button,cite,code,command,del,details,dfn,em,font,i,iframe,img,input,ins,kbd,label,map,mark,meter,nav,object,q,s,samp,script,select,small,span,strike,strong,sub,summary,sup,textarea,tt,u,time,var");

// Elements that you can, intentionally, leave open
// (and which close themselves)
var closeSelf = makeMap("colgroup,dd,dt,li,options,p,td,tfoot,th,thead,tr");

// Attributes that have their values filled in disabled="disabled"
var fillAttrs = makeMap("checked,compact,declare,defer,disabled,ismap,multiple,nohref,noresize,noshade,nowrap,readonly,selected");

// Special Elements (can contain anything)
var special = makeMap("script,style");

HTMLParser = function( html, handler ) {
	var index, chars, match, stack = [], last = html;
	stack.last = function(){
		return this[ this.length - 1 ];
	};

	function parseStartTag( tag, tagName, rest, unary ) {
		if ( block[ tagName ] ) {
			while ( stack.last() && inline[ stack.last() ] ) {
				parseEndTag( "", stack.last() );
			}
		}

		if ( closeSelf[ tagName ] && stack.last() === tagName ) {
			parseEndTag( "", tagName );
		}

		unary = empty[ tagName ] || !!unary;

		if ( !unary )
			stack.push( tagName );

		if ( handler.start ) {
			var attrs = [];

			rest.replace(attr, function(match, name) {
				var value = arguments[2] ? arguments[2] :
					arguments[3] ? arguments[3] :
					arguments[4] ? arguments[4] :
					fillAttrs[name] ? name : "";

				attrs.push({
					name: name,
					value: value,
					escaped: value.replace(/(^|[^\\])"/g, '$1\\\"') //"
				});
			});

			if ( handler.start )
				handler.start( tagName, attrs, unary );
		}
	}

	function parseEndTag( tag, tagName ) {
		var pos;

		// If no tag name is provided, clean shop
		if (!tagName) {
			pos = 0;
		}

		// Find the closest opened tag of the same type
		else
			for ( pos = stack.length - 1; pos >= 0; pos-- )
				if ( stack[ pos ] === tagName )
					break;

		if ( pos >= 0 ) {
			// Close all the open elements, up the stack
			for ( var i = stack.length - 1; i >= pos; i-- )
				if ( handler.end )
					handler.end( stack[ i ] );

			// Remove the open elements from the stack
			stack.length = pos;
		}
	}

	while ( html ) {
		chars = true;
		// Make sure we're not in a script or style element
		if ( !stack.last() || !special[ stack.last() ] ) {

			// Comment
			if ( html.indexOf("<!--") === 0 ) {
				index = html.indexOf("-->");

				if ( index >= 0 ) {
					if ( handler.comment )
						handler.comment( html.substring( 4, index ) );
					html = html.substring( index + 3 );
					chars = false;
				}

			// end tag
			} else if ( html.indexOf("</") === 0 ) {
				match = html.match( endTag );

				if ( match ) {
					html = html.substring( match[0].length );
					match[0].replace( endTag, parseEndTag );
					chars = false;
				}

			// start tag
			} else if ( html.indexOf("<") === 0 && !/^(<)[^>]*(?:<|$)/gm.test(html)) {
				match = html.match( startTag );

				if ( match ) {
					html = html.substring( match[0].length );
					match[0].replace( startTag, parseStartTag );
					chars = false;
				}
			}

			if ( chars ) {
				index = html.indexOf("<");
				if(/(<)[^>]*(?:<|$)/gm.test(html)){
					index = html.search(/(<)[^>]*(?:<|$)/gm)+1;
				}
				var text = index < 0 ? html : html.substring( 0, index );
				html = index < 0 ? "" : html.substring( index );

				if ( handler.chars )
					handler.chars( text );
			}

		} else {
			html = html.replace(new RegExp("(.*)<\/" + stack.last() + "[^>]*>"), function(all, text){
				text = text.replace(/<!--(.*?)-->/g, "$1")
					.replace(/<!\[CDATA\[(.*?)]]>/g, "$1");

				if (special[ stack.last() ]) {
					// Special tags, can contain anything, but, we need to prevent an exploit.
					// Without this, nothing prevent a hacker to simply do: purify('<script><script>alert()</script></script>')
					// and get '<script>alert()</script>' in the output.
					text = text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
				}

				if ( handler.chars )
					handler.chars( text );

				return "";
			});

			parseEndTag( "", stack.last() );
		}

		if ( html === last )
			throw "Parse Error: " + html;
		last = html;
	}

	// Clean up any remaining tags
	parseEndTag();
};