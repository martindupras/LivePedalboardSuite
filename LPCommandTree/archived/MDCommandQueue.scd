// MDCommandQueue.sc
// MD 20250801

MDCommandQueue{

	var <> queue;

	*new{
		^super.new.init();
	}

	init{
		this.queue = List.new(8);
		^this
	}


} // end of class MDCommandQueue