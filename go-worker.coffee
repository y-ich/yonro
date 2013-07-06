# worker IF

self.onmessage = (event) ->
    try
        history = event.data.history.map (e) -> OnBoard.fromString e
        if history[history.length - 2]?.isEqualTo history[history.length - 1]
            history[history.length - 2] = history[history.length - 1]
            if history[history.length - 3]?.isEqualTo history[history.length - 1]
                history[history.length - 3] = history[history.length - 1]
        result = evaluate history, event.data.next
        event.data.value = result.value
        event.data.history = result.history.map (e) -> e.toString()
    catch error
        # You need to copy properties in order to pass the property "message". 
        event.data.error =
            line: error.line
            message: error.message
            sourceURL: error.sourceURL
            stack: error.stack
    finally
        postMessage event.data
        close()