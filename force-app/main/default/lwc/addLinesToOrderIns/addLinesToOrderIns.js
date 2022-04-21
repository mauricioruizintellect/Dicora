import { LightningElement,api,track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import getInstalaciones from "@salesforce/apex/ControllerAddLinesToOrderIns.getInstalaciones";
import inserRecord from "@salesforce/apex/ControllerAddLinesToOrderIns.inserRecord";
import editRecord from "@salesforce/apex/ControllerAddLinesToOrderIns.editRecord";
import deleteRecord from "@salesforce/apex/ControllerAddLinesToOrderIns.deleteRecord";

export default class AddLinesToOrderIns extends LightningElement {
    @api recordId;
    showSpinner = true;
    @track allData = {};

    connectedCallback() {
        this.init();
    }
    init() {
        getInstalaciones({
            recordId: this.recordId
        }).then(response => {
            this.allData = response;
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
        if(field == 'cantidad'){
            this.allData.cantidad = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }else if(field == 'detalle'){
            this.allData.detalle = valor.trim() != '' ? valor : null;
        }else if(field == 'precio'){
            this.allData.precio = valor.trim() != '' ? valor : null;
            this.calcularTotal();
        }
        this.validaBoton();
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
        if(this.allData.cantidad != null && this.allData.precio != null && this.allData.detalle != null
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
    pushMessage(title,variant,msj){
        const message = new ShowToastEvent({
            "title": title,
            "variant": variant,
            "message": msj
            });
            this.dispatchEvent(message);
    }

    eventOnchangeCantiAgr(event){
        const nombre = event.target.name;
        const valor = event.target.value;
        for(let i=0; i<this.allData.listInstalacionesAgr.length; i++){
            if(nombre == this.allData.listInstalacionesAgr[i].id){
                this.allData.listInstalacionesAgr[i].cantidad = valor;
                this.allData.listInstalacionesAgr[i].total = this.allData.listInstalacionesAgr[i].precio * valor;
            }
        }
    }
    eventOnchangeDetaAgr(event){
        const nombre = event.target.name;
        const valor = event.target.value;
        for(let i=0; i<this.allData.listInstalacionesAgr.length; i++){
            if(nombre == this.allData.listInstalacionesAgr[i].id){
                this.allData.listInstalacionesAgr[i].detalle = valor;
            }
        }
    }
    eventOnchangePrecioAgr(event){
        const nombre = event.target.name;
        const valor = event.target.value;
        for(let i=0; i<this.allData.listInstalacionesAgr.length; i++){
            if(nombre == this.allData.listInstalacionesAgr[i].id){
                this.allData.listInstalacionesAgr[i].precio = valor;
                this.allData.listInstalacionesAgr[i].total = this.allData.listInstalacionesAgr[i].cantidad * valor;
            }
        }
    }
    editarRegistro(event){
        this.showSpinner = true;
        const lineaSeleccionada = event.target.name;
        for(let i=0; i<this.allData.listInstalacionesAgr.length; i++){
            if(lineaSeleccionada == this.allData.listInstalacionesAgr[i].id){
                editRecord({
                    recordId: lineaSeleccionada,
                    cantidad: this.allData.listInstalacionesAgr[i].cantidad,
                    precio: this.allData.listInstalacionesAgr[i].cantidad,
                    detalle: this.allData.listInstalacionesAgr[i].detalle,
                    ordenCompraId: this.recordId
                }).then(response => {
                    this.allData.listInstalacionesAgr[i].disabledBoton = true;
                    this.allData.listInstalacionesAgr[i].cantidadOrg = this.allData.listInstalacionesAgr[i].cantidad;
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
            for(let i=0; i<this.allData.listInstalacionesAgr.length; i++){
                if(lineaSeleccionada != this.allData.listInstalacionesAgr[i].id){
                    listTempo.push(this.allData.listInstalacionesAgr[i]);
                }
            }
            this.allData.listInstalacionesAgr = listTempo;
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