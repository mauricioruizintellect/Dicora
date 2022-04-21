import { LightningElement,api, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getMateriales from "@salesforce/apex/ControllerAddLinesToOrderMat.getMateriales";
import inserRecord from "@salesforce/apex/ControllerAddLinesToOrderMat.inserRecord";
import editRecord from "@salesforce/apex/ControllerAddLinesToOrderMat.editRecord";
import deleteRecord from "@salesforce/apex/ControllerAddLinesToOrderMat.deleteRecord";

import NAME_FIELD from '@salesforce/schema/OdenDeCompra__c.Name';

export default class AddLinesToOrderMat extends LightningElement {
    @api recordId;
    showSpinner = true;
    @track allData = {};
    listMateriales = [];
    campo = NAME_FIELD;

    connectedCallback() {
        this.init();
    }
    init() {
        getMateriales({
            recordId: this.recordId
        }).then(response => {
            this.allData = response;
            this.listMateriales = this.allData.listMateriales;
            this.showSpinner = false;
            this.calcularTotal();
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }

    eventOnchange(event){
        const field = event.target.name;
        const valor = event.target.value;
        if(field == 'material'){
            this.allData.material = valor;
            this.allData.precio = 0;
            for(let i=0; i<this.allData.listMateriales.length; i++){
                if(valor == this.allData.listMateriales[i].value){
                    this.allData.precio = this.allData.listMateriales[i].precio;
                }
            }
        }else if(field == 'precio'){
            this.allData.precio = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'cantidad'){
            this.allData.cantidad = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'filtro'){
            this.filtrarMateriales(valor.trim())
        }
        this.validaBoton();
    }
    filtrarMateriales(valorBusqueda){
        this.showSpinner = true;
        var listTempo = [];
        if(valorBusqueda != ''){
            for(let i=0; i<this.listMateriales.length; i++){
                if(this.listMateriales[i].label.includes(valorBusqueda)){
                    listTempo.push(this.listMateriales[i]);
                }
            }
            this.allData.listMateriales = listTempo;
        }else{
            this.allData.listMateriales = this.listMateriales;
        }
        this.showSpinner = false;
    }
    calcularTotal(){
        if(this.allData.cantidad != null && this.allData.precio != null){
            this.allData.total = this.allData.cantidad * this.allData.precio;
        }else{
            this.allData.total = 0;
        }
    }
    validaBoton(){
        this.allData.disabledBoton = true;;
        if(this.allData.cantidad != null && this.allData.precio != null && this.allData.material != null
            && this.allData.total != null && this.allData.total != 0){
            this.allData.disabledBoton = false;
        }
    }

    agregarOrdenCompra(){
        this.showSpinner = true;
        inserRecord({
            allData: JSON.stringify(this.allData)
        }).then(response => {
            this.init();
            this.pushMessage('Error', 'success', 'Datos guardados exitosamente.');
            eval("$A.get('e.force:refreshView').fire();");
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
    }
    eventOnchangeAgr(event){
        const nombre = event.target.name;
        const valor = event.target.value;
        for(let i=0; i<this.allData.listMaterialesAgr.length; i++){
            if(nombre == this.allData.listMaterialesAgr[i].id){
                this.allData.listMaterialesAgr[i].cantidad = valor;
                this.allData.listMaterialesAgr[i].total = this.allData.listMaterialesAgr[i].precio * valor;
                this.allData.listMaterialesAgr[i].disabledBoton = valor == this.allData.listMaterialesAgr[i].cantidadOrg ? true : false;
            }
        }
    }
    editarRegistro(event){
        this.showSpinner = true;
        const lineaSeleccionada = event.target.name;
        for(let i=0; i<this.allData.listMaterialesAgr.length; i++){
            if(!this.allData.listMaterialesAgr[i].disabledBoton && lineaSeleccionada == this.allData.listMaterialesAgr[i].id){
                editRecord({
                    recordId: lineaSeleccionada,
                    cantidad: this.allData.listMaterialesAgr[i].cantidad,
                    ordenCompraId: this.recordId
                }).then(response => {
                    this.allData.listMaterialesAgr[i].disabledBoton = true;
                    this.allData.listMaterialesAgr[i].cantidadOrg = this.allData.listMaterialesAgr[i].cantidad;
                    this.allData.iva = response.IVA__c;
                    this.allData.subTotal = response.Subtotal__c;
                    this.allData.totalOC = response.Total__c;
                    this.pushMessage('Exitosamente', 'success', 'Datos guardados exitosamente.');
                    this.showSpinner = false;
                }).catch(error => {
                    this.showSpinner = false;
                    this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
                });
            }
        }
    }

    eliminarRegistro(event){
        this.showSpinner = true;
        const lineaSeleccionada = event.target.name;
        deleteRecord({
            recordId: lineaSeleccionada,
            ordenCompraId: this.recordId
        }).then(response => {
            var listTempo = [];
            for(let i=0; i<this.allData.listMaterialesAgr.length; i++){
                if(lineaSeleccionada != this.allData.listMaterialesAgr[i].id){
                    listTempo.push(this.allData.listMaterialesAgr[i]);
                }
            }
            this.allData.listMaterialesAgr = listTempo;
            this.allData.iva = response.IVA__c;
            this.allData.subTotal = response.Subtotal__c;
            this.allData.totalOC = response.Total__c;
            this.pushMessage('Exitosamente', 'success', 'Datos guardados exitosamente.');
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.pushMessage('Error', 'error', 'Ha ocurrido un error, por favor contacte a su admin.');
        });
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