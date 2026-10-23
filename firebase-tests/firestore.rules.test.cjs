const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, collection, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } = require('firebase/firestore');
const fs = require('node:fs');
const path = require('node:path');

const projectId = 'demo-commonsapp-rules';
let env;
const alice = 'alice';
const bob = 'bob';
const pending = 'pending';
const admin = 'admin';
function db(uid, claims = {}) { return env.authenticatedContext(uid, claims).firestore(); }
function anon() { return env.unauthenticatedContext().firestore(); }
function userDoc(uid, status = 'approved') {
  return { name: uid, unit: 'A101', phone: '', email: `${uid}@example.test`, contactPreference: 'push', showUnitToNeighbors: true, approvalStatus: status, createdAt: Timestamp.fromMillis(1) };
}
function eventDoc(owner = admin, overrides = {}) {
  return { title: 'Meeting', description: '', date: Timestamp.fromMillis(Date.now() + 86400000), endDate: Timestamp.fromMillis(Date.now() + 90000000), location: 'Lobby', allowsRSVP: true, status: 'active', createdBy: owner, createdAt: Timestamp.fromMillis(1), updatedAt: Timestamp.fromMillis(1), ...overrides };
}
function slotDoc() { return { start: Timestamp.fromMillis(Date.now() + 86400000), members: [], updatedAt: Timestamp.fromMillis(1) }; }
async function seed() {
  await env.withSecurityRulesDisabled(async context => {
    const d = context.firestore();
    for (const [id, status] of [[alice,'approved'],[bob,'approved'],[pending,'pending'],[admin,'approved']]) await setDoc(doc(d,'users',id),userDoc(id,status));
    await setDoc(doc(d,'events','future'),eventDoc());
    await setDoc(doc(d,'events','cancelled'),eventDoc(admin,{status:'cancelled'}));
    await setDoc(doc(d,'events','past'),eventDoc(admin,{date:Timestamp.fromMillis(1),endDate:Timestamp.fromMillis(2)}));
    await setDoc(doc(d,'events','no-rsvp'),eventDoc(admin,{allowsRSVP:false}));
    await setDoc(doc(d,'gymSettings','main'),{capacity:1});
    await setDoc(doc(d,'gymSlots','slot1'),slotDoc());
    await setDoc(doc(d,'maintenanceRequests','m1'),{title:'Leak',details:'Kitchen leak',unit:'A101',residentId:alice,submittedAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1),stage:0});
    await setDoc(doc(d,'chats','chat1'),{participantIds:[alice,bob],createdAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1)});
    await setDoc(doc(d,'chats','chat2'),{participantIds:[bob,admin],createdAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1)});
  });
}

before(async () => {
  const rules = fs.readFileSync(path.resolve(__dirname,'../firestore.rules'),'utf8');
  env = await initializeTestEnvironment({ projectId, firestore: { rules } });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); await seed(); });

// User privacy and approval
test('anonymous cannot read user profile', async () => assertFails(getDoc(doc(anon(),'users',alice))));
test('resident can read own profile', async () => assertSucceeds(getDoc(doc(db(alice),'users',alice))));
test('resident cannot read another profile', async () => assertFails(getDoc(doc(db(alice),'users',bob))));
test('resident cannot approve themselves', async () => assertFails(updateDoc(doc(db(pending),'users',pending),{approvalStatus:'approved'})));
test('resident cannot delete own profile', async () => assertFails(deleteDoc(doc(db(alice),'users',alice))));
test('admin claim can read another profile', async () => assertSucceeds(getDoc(doc(db(admin,{admin:true}),'users',alice))));
test('pending resident cannot read events', async () => assertFails(getDoc(doc(db(pending),'events','future'))));
test('approved resident can read events', async () => assertSucceeds(getDoc(doc(db(alice),'events','future'))));

// Events and RSVP
test('resident cannot create event', async () => assertFails(setDoc(doc(db(alice),'events','new'),eventDoc(alice))));
test('resident cannot cancel event', async () => assertFails(updateDoc(doc(db(alice),'events','future'),{status:'cancelled',updatedAt:serverTimestamp()})));
test('approved resident can RSVP for future active event', async () => assertSucceeds(setDoc(doc(db(alice),'events','future','attendees',alice),{userId:alice,createdAt:serverTimestamp()})));
test('resident cannot RSVP as someone else', async () => assertFails(setDoc(doc(db(alice),'events','future','attendees',bob),{userId:bob,createdAt:serverTimestamp()})));
test('pending resident cannot RSVP', async () => assertFails(setDoc(doc(db(pending),'events','future','attendees',pending),{userId:pending,createdAt:serverTimestamp()})));
test('cancelled event rejects RSVP', async () => assertFails(setDoc(doc(db(alice),'events','cancelled','attendees',alice),{userId:alice,createdAt:serverTimestamp()})));
test('past event rejects RSVP', async () => assertFails(setDoc(doc(db(alice),'events','past','attendees',alice),{userId:alice,createdAt:serverTimestamp()})));
test('RSVP-disabled event rejects RSVP', async () => assertFails(setDoc(doc(db(alice),'events','no-rsvp','attendees',alice),{userId:alice,createdAt:serverTimestamp()})));
test('resident cannot update RSVP document', async () => {
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'events','future','attendees',alice),{userId:alice,createdAt:Timestamp.fromMillis(1)}));
  await assertFails(updateDoc(doc(db(alice),'events','future','attendees',alice),{userId:bob}));
});
test('resident can remove own RSVP', async () => {
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'events','future','attendees',alice),{userId:alice,createdAt:Timestamp.fromMillis(1)}));
  await assertSucceeds(deleteDoc(doc(db(alice),'events','future','attendees',alice)));
});

// Maintenance
test('resident can read own maintenance request', async () => assertSucceeds(getDoc(doc(db(alice),'maintenanceRequests','m1'))));
test('resident cannot read another maintenance request', async () => assertFails(getDoc(doc(db(bob),'maintenanceRequests','m1'))));
test('resident cannot advance maintenance stage', async () => assertFails(updateDoc(doc(db(alice),'maintenanceRequests','m1'),{stage:1,updatedAt:serverTimestamp()})));
test('admin can advance maintenance stage by one', async () => assertSucceeds(updateDoc(doc(db(admin,{admin:true}),'maintenanceRequests','m1'),{stage:1,updatedAt:serverTimestamp()})));
test('admin cannot skip maintenance stage', async () => assertFails(updateDoc(doc(db(admin,{admin:true}),'maintenanceRequests','m1'),{stage:2,updatedAt:serverTimestamp()})));

// Gym
test('resident cannot change gym capacity', async () => assertFails(updateDoc(doc(db(alice),'gymSettings','main'),{capacity:2})));
test('admin can change gym capacity within bounds', async () => assertSucceeds(updateDoc(doc(db(admin,{admin:true}),'gymSettings','main'),{capacity:2})));
test('admin cannot set zero gym capacity', async () => assertFails(updateDoc(doc(db(admin,{admin:true}),'gymSettings','main'),{capacity:0})));
test('resident can book available gym slot', async () => assertSucceeds(updateDoc(doc(db(alice),'gymSlots','slot1'),{members:[alice],updatedAt:serverTimestamp()})));
test('gym slot cannot exceed capacity', async () => {
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(),'gymSlots','slot1'),{members:[alice]}));
  await assertFails(updateDoc(doc(db(bob),'gymSlots','slot1'),{members:[alice,bob],updatedAt:serverTimestamp()}));
});
test('resident cannot remove another member from gym slot', async () => {
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(),'gymSlots','slot1'),{members:[alice]}));
  await assertFails(updateDoc(doc(db(bob),'gymSlots','slot1'),{members:[],updatedAt:serverTimestamp()}));
});
test('resident can cancel own gym booking', async () => {
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(),'gymSlots','slot1'),{members:[alice]}));
  await assertSucceeds(updateDoc(doc(db(alice),'gymSlots','slot1'),{members:[],updatedAt:serverTimestamp()}));
});

// Chat
test('chat participant can read conversation', async () => assertSucceeds(getDoc(doc(db(alice),'chats','chat1'))));
test('nonparticipant cannot read conversation', async () => assertFails(getDoc(doc(db(admin,{admin:true}),'chats','chat1'))));
test('participant can send message', async () => assertSucceeds(setDoc(doc(db(alice),'chats','chat1','messages','msg1'),{senderId:alice,text:'Hello',createdAt:serverTimestamp()})));
test('participant cannot impersonate another sender', async () => assertFails(setDoc(doc(db(alice),'chats','chat1','messages','msg1'),{senderId:bob,text:'Hello',createdAt:serverTimestamp()})));
test('nonparticipant cannot send message', async () => assertFails(setDoc(doc(db(admin,{admin:true}),'chats','chat1','messages','msg1'),{senderId:admin,text:'Hello',createdAt:serverTimestamp()})));
test('empty chat message is rejected', async () => assertFails(setDoc(doc(db(alice),'chats','chat1','messages','msg1'),{senderId:alice,text:'',createdAt:serverTimestamp()})));
