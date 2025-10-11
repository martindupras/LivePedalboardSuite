// CommandTree/MDCommandQueue_Compat_AddAlias.sc
// v1.0.1
// MD 20250924-1249
/*
Purpose:
- Keep older tests working: addCommand -> enqueueCommand.
*/

+ MDCommandQueue {
    addCommand { |command|
        var result;
        result = this.enqueueCommand(command);
        result
    }
}
