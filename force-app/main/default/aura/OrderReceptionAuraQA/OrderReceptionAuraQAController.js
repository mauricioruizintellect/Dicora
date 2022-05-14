({
    activeProcessItems : function(component, event, helper) {
        let receptionMaterial = component.find("orderReceptionlLWC");
        // Forzamos el componente a mostrar la llamada actual
        receptionMaterial.receptionOrderItems();
    },
    cancel :  function(component, event, helper) {
        const dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})
