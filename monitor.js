const si = require('systeminformation');
const os = require('os');
const http = require('http');

var monitor = {};
//---------------------------------------
//---------------------------------------
//---------------------------------------
monitor.get_cpu_load = function(callback){
  try{
    var cpu = os.cpus(), cpu_data = null;

    if(monitor.prev_cpu){
      var cores = [];

      for(var i in cpu){
        var nt = cpu[i].times, pt = monitor.prev_cpu[i].times;
        var run_time = (nt.user - pt.user)
                     + (nt.nice - pt.nice)
                     + (nt.sys - pt.sys)
                     + (nt.irq - pt.irq);
        var idle_time = nt.idle - pt.idle;
        cores.push(100 * run_time / (idle_time + run_time));
      }
      
      cpu_data = {cpu: cores.reduce((a, b) => a + b) / cores.length, cores: cores};
    }

    monitor.prev_cpu = cpu;
    if(callback) callback(null, cpu_data);
  } catch(error){
    if(callback) callback(error);
  }
};

//---------------------------------------
monitor.get_cpu_temp = function(callback){
  si.cpuTemperature().then(temp => callback(null, temp)).catch(error => callback(error));
};

//---------------------------------------
monitor.get_mem = function(callback){
  si.mem().then(mem => callback(null, mem)).catch(error => callback(error));
};

//---------------------------------------
monitor.send_data = function(payload){
  payload = JSON.stringify(payload);
  var options = {
    hostname: '192.168.68.201',
    path: '/api/stats/send',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': payload.length
    }
  };

  var data = '';
  var req = http.request(options, (res) => {
    res.on('data', (chunk) => {data += chunk;});
    res.on('end', () => {console.log('Stats Successfully sent.');});
  }).on("error", (err) => {console.error("Error: ", err.message);});

  req.write(payload);
  req.end();
};

//---------------------------------------
monitor.run_monitor = function(){
  monitor.get_cpu_load(function(err, cpu){
    if(err) console.error(err);

    monitor.get_cpu_temp(function(err, temp){
      if(err) console.error(err);

      monitor.get_mem(function(err, mem){
        if(err) console.error(err);

        monitor.send_data({mem: mem, cpu: cpu, temp: temp});
      });
    });
  });
};

//---------------------------------------
monitor.start_monitor = function(interval = 5){
  monitor.get_cpu_load();
  monitor.monitor = setInterval(monitor.run_monitor, interval*1000);
};

//---------------------------------------
monitor.stop_monitor = function(){
  clearInterval(monitor.monitor);
};

//---------------------------------------
//---------------------------------------
//---------------------------------------
module.exports = monitor;
monitor.start_monitor(60);
