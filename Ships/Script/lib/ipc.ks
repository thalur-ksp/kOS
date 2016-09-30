// lib/ipc: inter-processor communication
RUNONCEPATH("lib/io").
RUNONCEPATH("lib/enum").

{
    global ipc is lexicon().
    
    
    ipc:Add("RegisterWithScheduler", RegisterWithScheduler@).
    FUNCTION RegisterWithScheduler
    {
        PARAMETER scheduler.
        
        scheduler["RegisterAction"]("ipc_ActivatePayload", ActivatePayload@, 1).
    }    
    
    ipc:Add("broadcast", BroadcastInShip@).
    FUNCTION BroadcastInShip
    {
        parameter message.
        
        LIST Processors in allProcs.
        
        FOR proc in allProcs
        {
            if (proc <> core)
            {
                proc:connection:sendMessage(message).
            }
        }
    }
    
    // Checks if the processor queue contains a message that matches the
    // predicate. Returns true if found and leaves the matching message
    // at the head of the queue.
    ipc:Add("checkProcessorForMessage", CheckProcessorForMessage@).
    FUNCTION CheckProcessorForMessage
    {
        parameter predicate.
        
        local queue is core:messages.
        local count is queue:length.
        FROM {local x is 0.} UNTIL x = count STEP {set x to x+1.} DO
        {
            local msg is queue:peek().
            if (predicate(msg))
            {
                return true.
            }
            queue:pop().
            queue:push(msg).
        }
        return false.
    }
    
    ipc:Add("activatePayload", ActivatePayload@).
    FUNCTION ActivatePayload
    {
        BroadcastInShip("activatePayload").
    }
    
    ipc:Add("PayloadWaitUntilActivated", PayloadWaitUntilActivated@).
    FUNCTION PayloadWaitUntilActivated
    {
        WAIT UNTIL CheckProcessorForMessage({ parameter m. return m = "activatePayload". }).
    }
}