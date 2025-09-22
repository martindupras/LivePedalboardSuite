// MDLogFacade
// v1.0.0
// MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


// Minimal logging facade so any object can call: this.mdlog(level, label, message)
+ Object {
    mdlog { |level = 2, label = "GENERIC", message = ""|
        var logger = MDMiniLogger.get;
        switch(level,
            0, { logger.error(label, message) },
            1, { logger.warn(label, message) },
            2, { logger.info(label, message) },
            3, { logger.debug(label, message) },
            4, { logger.trace(label, message) }
        );
        ^this
    }
}
