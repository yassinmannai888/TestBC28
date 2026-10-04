(function () {
    var host = document.getElementById('controlAddIn');
    host.innerHTML =
        '<div class="csc-wrapper">' +
        '  <div class="csc-message" id="cscMessage" hidden></div>' +
        '  <div class="csc-canvas-box"><canvas id="cscCanvas"></canvas></div>' +
        '</div>';

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
})();
