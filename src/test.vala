namespace Vera {

	int main(string[] args) {
		
		Gdk.init(ref args);
		
		Launcher launcher = new Launcher({"tint2"}, true, false, true);
		launcher.launch();
		
		return 0;
		
	}

}
