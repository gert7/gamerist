var amq = require('amq');

var connection = amq.createConnection({ host : 'localhost' , debug : true },{ 
    reconnect : { strategy : 'constant' , initial : 1000 } 
});
var queue = connection.queue( '' );
