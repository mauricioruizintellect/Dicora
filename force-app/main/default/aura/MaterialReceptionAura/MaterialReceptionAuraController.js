({
    activeProcessItems : function(component, event, helper) {
        let receptionMaterial = component.find("receptionMaterialLWC");
        // Forzamos el componente a mostrar la llamada actual
        receptionMaterial.processItems(event);
    },
    cancel :  function(component, event, helper) {
        const dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})
