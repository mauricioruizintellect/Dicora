import { LightningElement,api, track } from 'lwc';
import getListOption from "@salesforce/apex/ControllerAssignStructures.getListOption";
import insertRecord from "@salesforce/apex/ControllerAssignStructures.insertRecord";
import getMedium from "@salesforce/apex/ControllerAssignStructures.getMedium";
import getInstalador from "@salesforce/apex/ControllerAssignStructures.getInstalador";
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import sitio from '@salesforce/schema/Sitio__c.Name';


export default class AssignStructures extends LightningElement {
    @api recordId;
    @track allData = {};
    showSpinner = true;
    listMedios = [];
    nombreSitio = sitio;


    connectedCallback() {
        this.init();
    }
    init() {
        this.showSpinner = true;
        getListOption({
            recordId: this.recordId
          })
          .then((response) => {
            if(response != null){
                this.allData = response;
                if(response.asignacionesDisponibles < 1){
                    this.pushMessage('Advertencia', 'warning', 'Actualmente no hay estructuras en bodega.');
                }
            }
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });

    }
    eventOnchange(event){
        let nameField = event.target.name;
        let valueFiel = event.target.value;
        if(nameField == 'sitio'){
            this.allData.sitioSelecionado = valueFiel;
            this.eventOnchangeSitio();
        }else if(nameField == 'medio'){
            this.allData.medioSelecionado = valueFiel;
        }else if(nameField == 'instalador'){
            this.allData.usuarioSelecionado = valueFiel;
        }else if(nameField == 'proveedor'){
            this.allData.proveedorSelecionado = valueFiel;
        }else if(nameField == 'fecha'){
            this.allData.fecha = valueFiel;
        }else if(nameField == 'costo'){
            this.allData.costo = valueFiel;
        }
    }
    eventOnchangeSitio(){
        this.showSpinner = true;
        this.allData.listMedios = [];
        getMedium({
            sitioId: this.allData.sitioSelecionado
          })
          .then((response) => {
            if(response.length > 0){
                this.allData.listMedios = response;
                this.listMedios = response;
            }else{
                this.allData.listMedios = [];
                this.pushMessage('Advertencia', 'warning', 'No se han encontrado medios');
            }
            this.getInstalador();
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
        
    }

    getInstalador(){
        this.allData.listUsuarios = [];
        this.allData.usuarioSelecionado = null;
        getInstalador({
            sitioId: this.allData.sitioSelecionado
          })
          .then((response) => {
            if(response.length > 0){
                this.allData.listUsuarios = response;
                this.allData.usuarioSelecionado = response[0].value;
            }else{
                this.allData.listUsuarios = [];
                this.pushMessage('Advertencia', 'warning', 'No se han encontrado instaladores');
            }
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
        
    }
    onClickSave(){
        this.showSpinner = true;
        if(this.allData.sitioSelecionado != null && this.allData.medioSelecionado != null && this.allData.usuarioSelecionado != null &&
            this.allData.costo != null && this.allData.fecha != null){
                insertRecord({
                    data: JSON.stringify(this.allData)
                  })
                  .then((response) => {
                    console.log('Respuesta: '+response);
                    this.pushMessage('Exitoso', 'success', 'Datos guardados con exito.');
                    this.allData.asignacionesDisponibles  = this.allData.asignacionesDisponibles - 1;
                    if(this.allData.asignacionesDisponibles == 0){
                        this.allData.disabledBoton = true;
                    }
                    eval("$A.get('e.force:refreshView').fire();");
                    this.showSpinner = false;
                }).catch(error => {
                    this.showSpinner = false;
                    this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
                });
        }else{
            this.pushMessage('Advertencia', 'warning', 'Debe completar todos lo campos.');
        }
        this.showSpinner = false;
    }
    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
            this.dispatchEvent(message);
    }

}