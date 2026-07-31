({
    doInit : function(component, event, helper) { 
        console.log("recordId -> " + component.get('v.recordId'));

        var pageRef = component.get("v.pageReference");
        var state = pageRef.state; // state holds any query params
        var base64Context = state.inContextOfRef;
        var recid;
        if (base64Context && base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        
            var addressableContext = JSON.parse(window.atob(base64Context));

            recid = addressableContext.attributes.recordId;

        }

        if(recid){
            component.set("v.vaesId",recid);
        }
    }
})