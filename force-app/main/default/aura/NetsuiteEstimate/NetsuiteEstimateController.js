({
   init : function(component, event, helper) {
      var action = component.get("c.getEstimate");
      action.setParams({"oppId": component.get("v.recordId")});
      action.setCallback(this, function(response) {
         var state = response.getState();
         if(component.isValid() && state == "SUCCESS" && response.getReturnValue() == "Ok"){
            component.set("v.messageError", 'Synchronization completed.');
			component.set("v.messageErrorBoolean", false);
			$A.get('e.force:refreshView').fire();
         } else {
            component.set("v.messageError", response.getReturnValue());
            component.set("v.messageErrorBoolean", true);
         }
      });
      $A.enqueueAction(action);
   }
})