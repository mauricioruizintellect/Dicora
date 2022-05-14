({
    cancel :  function(component, event, helper) {
        const dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})
