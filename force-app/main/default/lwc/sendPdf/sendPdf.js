import { LightningElement,api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/OrderReceptionController.sendEmail';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import EMAIL_ADDRESS from '@salesforce/schema/OdenDeCompra__c.Proveedor__r.Correo__c';
import bodyTemplate from '@salesforce/label/c.plantillaEmailOC';


export default class SendPdf extends LightningElement {
   @api recordId;
   @api objectApiName;
   isModalOpen = false;
   isLoadingSpinner = false;
   label = {bodyTemplate};

   @wire(getRecord, { recordId: '$recordId', fields: [EMAIL_ADDRESS] })
    orderInfo;
    get email() {
        return getFieldValue(this.orderInfo.data, EMAIL_ADDRESS);
    }

   get urlFile(){
    return "/apex/OrderSendPdf?id="+this.recordId
   }
  
   sendEmail(e) {
        let emailInput = this.template.querySelector(".email");
        let emailInputCc = this.template.querySelector(".email2");
        let bodyInput = this.template.querySelector(".body");
        let emailValue = emailInput.value;
        let emailValueCc = emailInputCc.value;
        let bodyValue = bodyInput.value;
        if(emailValue == "" || emailValue == null){
            emailInput.reportValidity();
            return null;
        }
        if(emailValueCc != ""){
            if(!emailInputCc.reportValidity()){
                return null;
            }
        }
        if(bodyValue == "" || bodyValue == null){
            bodyInput.reportValidity();
            return null;
        }
        this.isLoadingSpinner = true;
         sendEmail({
            email: emailValue,
            recordId: this.recordId,
            emailCC: emailValueCc,
            body:bodyValue
        }).then(result => {
            this.showToast('Envío PDF','EL archivo se envío exitosamente','success');
            this.isLoadingSpinner = false;
            this.dispatchEvent(new CustomEvent('close'));
            this.cancel();
        }).catch(error => {
            this.showToast('Envío PDF',error,'error');
            this.isLoadingSpinner = false;
        }) 
   }

   cancel(event){
    this.dispatchEvent(new CloseActionScreenEvent());
   }

   closeSetEmail(event){
     this.isModalOpen = false
   }

   handleModalEmail(event){
       this.isModalOpen = !this.isModalOpen;
   }

   showToast(title,message,variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(event);
}
}