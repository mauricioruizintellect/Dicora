/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
import { LightningElement,api } from 'lwc';
import saveSign from '@salesforce/apex/OrderReceptionController.saveSign';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//declaration of variables for calculations
let isDownFlag, 
    isDotFlag = false,
    prevX = 0,
    currX = 0,
    prevY = 0,
    currY = 0;            
       
let x = "#0000A0"; //blue color
let y = 1.5; //weight of line width and dot.       

let canvasElement, ctx; //storing canvas context
let attachment; //holds attachment information after saving the sigture on canvas
let dataURL,convertedDataURI; //holds image data

export default class CapturequestedEventignature extends LightningElement {
    @api recordId;
    @api idsToSignature;
    @api title = 'Firma de recibido'
    @api fileName = 'Firma'
    @api buttonLabel = 'Guardar';
    isLoadingSpinner = false;

    //event listeners added for drawing the signature within shadow boundary
    constructor() {
        super();
        this.template.addEventListener('mousemove', this.handleMouseMove.bind(this));
        this.template.addEventListener('mousedown', this.handleMouseDown.bind(this));
        this.template.addEventListener('mouseup', this.handleMouseUp.bind(this));
        this.template.addEventListener('mouseout', this.handleMouseOut.bind(this));
        this.template.addEventListener('touchstart', this.handleTouchStart.bind(this));
        this.template.addEventListener('touchmove', this.handleTouchMove.bind(this));
        this.template.addEventListener('touchend', this.handleTouchEnd.bind(this));
    }

    //retrieve canvase and context
    renderedCallback(){
        canvasElement = this.template.querySelector('canvas');
        ctx = canvasElement.getContext("2d");
    }
    
    //handler for mouse move operation
    handleMouseMove(event){
        this.searchCoordinatesForEvent('move', event);      
    }
    
    //handler for mouse down operation
    handleMouseDown(event){
        this.searchCoordinatesForEvent('down', event);         
    }
    
    //handler for mouse up operation
    handleMouseUp(event){
        this.searchCoordinatesForEvent('up', event);       
    }

    //handler for mouse out operation
    handleMouseOut(event){
        this.searchCoordinatesForEvent('out', event);         
    }

    //handler for touch start operation
    handleTouchStart(event){
        this.searchCoordinatesForEvent('start', event);         
    }

    //handler for touch move operation
    handleTouchMove(event){
        this.searchCoordinatesForEvent('moves', event);         
    }

    //handler for touch end operation
    handleTouchEnd(event){
        this.searchCoordinatesForEvent('end', event);         
    }
    
    /*
        handler to perform save operation.
        save signature as attachment.
        after saving shows success or failure message as toast
    */

    handleSaveClick(){   
        //set to draw behind current content
        ctx.globalCompositeOperation = "destination-over";
        ctx.fillStyle = "#FFF"; //white
        ctx.fillRect(0,0,canvasElement.width, canvasElement.height); 

        //convert to png image as dataURL
        dataURL = canvasElement.toDataURL("image/png");
        //convert that as base64 encoding
        convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        this.isLoadingSpinner = true;
        //call Apex method imperatively and use promise for handling sucess & failure
        saveSign({strSignElement: convertedDataURI,recId : this.recordId, idsToSave:this.idsToSignature, fileName:this.fileName})
            .then(result => {
                this.isLoadingSpinner = false;
                this.closeSignature();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Firma',
                        message: 'Firma guardada exitosamente',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                //show error message
                this.isLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating Salesforce File record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });        
    }

    //clear the signature from canvas
    handleClearClick(){
        ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);   
    }

    searchCoordinatesForEvent(requestedEvent, event){
        if (requestedEvent === 'down') {
            event.preventDefault();
            this.setupCoordinate(event);           
            isDownFlag = true;
            isDotFlag = true;
            if (isDotFlag) {
                this.drawDot();
                isDotFlag = false;
            }
        }
        if (requestedEvent === 'start' && event.target == canvasElement) {
            //event.preventDefault();
            this.setupCoordinates(event.touches[0]);           
            isDownFlag = true;
            isDotFlag = true;
            if (isDotFlag) {
                this.drawDot();
                isDotFlag = false;
            }
        }
        if (requestedEvent === 'up' || requestedEvent === 'out') {
            event.preventDefault();
            isDownFlag = false;
        }
        if (requestedEvent === 'end' && event.target == canvasElement) {
            event.preventDefault();
            isDownFlag = false;
        }
        if (requestedEvent === 'move') {
            event.preventDefault();
            if (isDownFlag) {
                this.setupCoordinate(event);
                this.redraw();
            }
        }
        if (requestedEvent === 'moves' && event.target == canvasElement) {
            event.preventDefault();
            if (isDownFlag) {
                this.setupCoordinates(event.touches[0]);
                this.redraw();
            }
        }
    }

    //This method is primary called from mouse down & move to setup cordinates.
    setupCoordinate(eventParam){
        //get size of an element and its position relative to the viewport 
        //using getBoundingClientRect which returns left, top, right, bottom, x, y, width, height.
        const clientRect = canvasElement.getBoundingClientRect();
        prevX = currX;
        prevY = currY;
        currX = eventParam.clientX -  clientRect.left;
        currY = eventParam.clientY - clientRect.top;
    }

    setupCoordinates(eventParam){
        //get size of an element and its position relative to the viewport 
        //using getBoundingClientRect which returns left, top, right, bottom, x, y, width, height.
        const clientRect = canvasElement.getBoundingClientRect();
        prevX = currX;
        prevY = currY;
        currX = eventParam.clientX -  clientRect.left;
        currY = eventParam.clientY - clientRect.top;
    }

    //For every mouse move based on the coordinates line to redrawn
    redraw() {
        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(currX, currY);
        ctx.strokeStyle = x; //sets the color, gradient and pattern of stroke
        ctx.lineWidth = y;        
        ctx.closePath(); //create a path from current point to starting point
        ctx.stroke(); //draws the path
    }
    
    //this draws the dot
    drawDot(){
        ctx.beginPath();
        ctx.fillStyle = x; //blue color
        ctx.fillRect(currX, currY, y, y); //fill rectrangle with coordinates
        ctx.closePath();
    }

    closeSignature(event) {
        this.dispatchEvent(new CustomEvent('close'));
	}
}