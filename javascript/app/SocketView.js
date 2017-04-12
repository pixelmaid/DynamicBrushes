//SocketView.js
'use strict';
define(["jquery"],

    function($) {
        var statusInput, connectBtn, requestBtn;

        var SocketView = class {

            constructor(model, element) {
                this.el = $(element);
                this.model = model;
                statusInput = this.el.find("#socket_status");
                connectBtn = this.el.find("#connect_btn");
                requestBtn = this.el.find("#request_btn");

                var self = this;

                requestBtn.click(function() {

                    self.requestBehaviorData(self.model);
                });

                connectBtn.click(function() {

                    self.model.connect();
                    statusInput.val("connecting");
                });
                this.model.addListener("ON_CONNECTION", this.onConnection);
                this.model.addListener("ON_DISCONNECT", this.onDisconnect);

            }

            onConnection() {
                statusInput.val("connected");
                connectBtn.prop("disabled", true);
            }


            onDisconnect() {
                statusInput.val("disconnected");
                connectBtn.prop("disabled", false);
            }


            requestBehaviorData(model) {
                var message = {
                    type: "data_request",
                    request: "all_behaviors",
                    requester: "authoring"
                };
               model.sendMessage(message);
            }


        };

        return SocketView;

    });