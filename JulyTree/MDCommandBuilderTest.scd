// MDCommandBuilderTest.scd
// MD 20250801

// FOR THIS TO WORK: we need to rund MDCommandNodeTest (version 20250731) because we need a populated tree ("tree")


/*// run this for debugging messages
(~mdDebug = true;

+Object {
    debug { |msg|
        if (~mdDebug == true) {
            msg.postln;
        };
    }
}
)*/



// Setup
~builder = MDCommandBuilder.new(~tree);
~queue = MDCommandQueue.new;

// Explore
~builder.listChildren;
~builder.navigateToChild(3); // e.g. Branch A
~builder.listChildren;
~builder.navigateToChild(7); // e.g. Twig A1b
~builder.printCurrentPath;

~builder.getCurrentCommand;
// Add to queue
~queue.addCommand(~builder.getCurrentCommand);

~builder.reset; // we need this to start at root again

// Explore
~builder.listChildren;
~builder.navigateToChild(5); // e.g. Branch A
~builder.listChildren;
~builder.navigateToChild(11); // e.g. Twig A1b
~builder.printCurrentPath;

~builder.getCurrentCommand;
// Add to queue
~queue.addCommand(~builder.getCurrentCommand);

// Export
~queue.queue.postln; // To inspect queue contents directly
~queue.exportToEnv;

~commandToSend;

