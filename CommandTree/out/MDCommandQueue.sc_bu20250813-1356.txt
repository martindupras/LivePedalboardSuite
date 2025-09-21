// MDCommandQueue.sc
// MD 20250801


// The purpose of this class is to enqueud the commands found in the tree; when the queue is complete, we invoke .exportToEnv which outputs the queue to the environment variable ~commandToSend. It will then be sent to PD to build a graph, eventually to SC instead.

MDCommandQueue{

	var <> queue;

	*new{
		^super.new.init();
	}

	init{
		this.queue = List.new(8);
		"Queue created".postln;
		^this
	}

	addCommand{
		|argCommand|
		this.queue.add(argCommand);
		postln("Command added to queue");
		postln(this.queue);
		^queue
	}

	removeLastCommand{
		if(this.queue.notEmpty){
			this.queue.removeAt(this.queue.size-1); // should remove last element of the list
			postln("Last command removed");
		}{
			postln("No command in queue");
		}
	}


	exportToEnv{
		~commandToSend = "/" ++ queue.join("/"); // make it OSC formatted
		~commandToSend.postln;
	}

} // end of class MDCommandQueue