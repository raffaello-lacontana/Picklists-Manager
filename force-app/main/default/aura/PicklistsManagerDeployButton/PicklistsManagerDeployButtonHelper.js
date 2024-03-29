({
	deploy : function(component, event, helper) {
        var action = component.get("c.deploy");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    mode: 'dismissible',
                    type: 'success',
                    message: 'Success! The JobId is ' + response.getReturnValue()
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                console.log(response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})