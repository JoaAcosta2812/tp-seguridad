const vm=require('node:vm'),fs=require('node:fs'),assert=require('node:assert/strict');
const nodes=new Map(),storage=new Map();
function node(k){if(!nodes.has(k))nodes.set(k,{innerHTML:'',textContent:'',style:{},dataset:{},classList:{toggle(){}},addEventListener(){},showModal(){},close(){}});return nodes.get(k)}
const context={window:{PULSO_CONFIG:{}},document:{querySelector:node,querySelectorAll:()=>[]},localStorage:{getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)},Date,crypto:require('node:crypto').webcrypto,setTimeout:()=>0,clearTimeout(){},console};
vm.createContext(context);vm.runInContext(fs.readFileSync('dist/app.js','utf8'),context);
(async()=>{
 await vm.runInContext(`(async()=>{let c=classes.find(c=>new Date(c.starts_at)>new Date());globalThis.testId=c.id;globalThis.before=c.occupied;await mutateReservation(c,false)})()`,context);
 assert.equal(vm.runInContext('bookings.length',context),1);assert.equal(vm.runInContext('classes.find(c=>c.id===testId).occupied',context),vm.runInContext('before+1',context));
 vm.runInContext("page='bookings';render()",context);assert.match(node('#view').innerHTML,/Reservado/);
 await vm.runInContext('mutateReservation(classes.find(c=>c.id===testId),true)',context);assert.equal(vm.runInContext('bookings.length',context),0);
 await vm.runInContext(`(async()=>{let c=classes.find(c=>c.id===testId);c.occupied=c.capacity;await mutateReservation(c,false)})()`,context);assert.equal(vm.runInContext('bookings.length',context),0);
 vm.runInContext("page='profile';render()",context);assert.match(node('#view').innerHTML,/profile-form/);
 vm.runInContext("page='admin';render()",context);assert.match(node('#admin-list').innerHTML,/data-edit/);
 assert.equal(JSON.parse(storage.get('pulso_bookings')).length,0);
 console.log('PASS: render agenda, reservar, mis turnos, cancelar, cupo completo, persistencia, perfil y panel admin.');
})().catch(e=>{console.error(e);process.exitCode=1});
