$(document).ready(
function () {
    var fontSize = $("#logEvents").css('font-size');
    var pageSize = $("#logBox").height() - parseFloat(fontSize) * 2;
    
    // FIXME: port hard-coded, but able to be set in pom.xml
    /* Connects to our local LogSocketServlet to read logs */
    var socket = new WebSocket('ws://localhost:8888/logs');
    
    /* Opens a new log file for reading */
    socket.onopen = function () {
        // Open the log we've set as our 'active' log (in this case, the default)
        openNewLog();
        console.log('New djatoka.log opened');
    }
    
    /* Outputs log events as it receives them */
    socket.onmessage = function (logEvent) {
        $("#logEvents").append("<div>" + logEvent + "</div>");
    }
    
    socket.onerror = function(logError) {
        console.log('Error: ' + logError.data);
    }
    
    socket.onclose = function() {
        console.log('Connection closed');
    }
    
    /* Change active class to the clicked link (i.e., log file) */
    $(".logfile").click(function (event) {
        event.preventDefault();
        $(".active").removeClass("active");
        $(this).addClass("active");
        
        // Open the log we've just marked as 'active'
        openNewLog();
        scrollEvents();
    });
    
    /* Open a new djatoka log */
    function openNewLog() {
        timestamp = new Date().toISOString();
        log = $(".active").text();
        span = "<span class='active'>" + log + "</span>";
        newLogEvent = "Opening " + span + " log ... [" + timestamp + "]";
        $("#logEvents").append("<div>" + newLogEvent + "</div>");
        
        // Tell server we want to open a new log
        socket.send('log:' + log);
    }
    
    /* Once we reach bottom of div, start scrolling new events as they happen */
    function scrollEvents() {
        height = $("#logEvents").height();
        
        if (height > pageSize) {
            $("#logBox").scrollTop(height);
        }
    }
    
    // Add future-proof 'startsWith' function; source:
    // http://stackoverflow.com/questions/646628/javascript-startswith
    if (typeof String.prototype.startsWith != 'function') {
        String.prototype.startsWith = function (string) {
            return this.slice(0, string.length) == string;
        };
    }
    
    // Override only if native toISOString is not defined; source:
    // http://stackoverflow.com/questions/11440569/converting-a-normal-date-to-iso-8601-format
    if (! Date.prototype.toISOString) {
        // Here we rely on JSON serialization for dates because it matches
        // the ISO standard. However, we check if JSON serializer is present
        // on a page and define our own .toJSON method only if necessary
        if (! Date.prototype.toJSON) {
            Date.prototype.toJSON = function (key) {
                function f(n) {
                    // Format integers to have at least two digits.
                    return n < 10 ? '0' + n: n;
                }
                
                return this.getUTCFullYear() + '-' +
                f(this.getUTCMonth() + 1) + '-' +
                f(this.getUTCDate()) + 'T' +
                f(this.getUTCHours()) + ':' +
                f(this.getUTCMinutes()) + ':' +
                f(this.getUTCSeconds()) + 'Z';
            };
        }
        
        Date.prototype.toISOString = Date.prototype.toJSON;
    }
});