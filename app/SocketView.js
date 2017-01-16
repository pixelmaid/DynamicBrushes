//SocketView.js
'use strict';
define (["jquery"],

function($){
var statusInput, connectBtn;

	var SocketView = class{

		constructor(model, element){
	       this.el = $(element);
           this.model = model;
          statusInput = this.el.find("#socket_status");
        connectBtn =  this.el.find("#connect_btn");

           var self = this;
         
           connectBtn.click(function(){
               
                self.model.connect();
                statusInput.val("connecting");
            });
            this.model.addListener("ON_CONNECTION",this.onConnection);
         this.model.addListener("ON_DISCONNECT",this.onDisconnect);

  		}

         onConnection(){
             statusInput.val("connected");
             connectBtn.prop("disabled",true);
        }


         onDisconnect(){
             statusInput.val("disconnected");
             connectBtn.prop("disabled",false);
        }


		
  
     
   

    };

    return SocketView;

});
