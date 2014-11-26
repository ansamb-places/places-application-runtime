if(process.platform === 'darwin')
{
	var nw = require('nw.gui');
	var win = nw.Window.get();
	var nativeMenuBar = new nw.Menu({ type: "menubar" });
	nativeMenuBar.createMacBuiltin("Places");
	win.menu = nativeMenuBar;
}